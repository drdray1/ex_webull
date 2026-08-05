defmodule ExWebull.Mqtt.Connection do
  @moduledoc """
  GenServer wrapping `Tortoise311` for Webull's MQTT v3.1.1 market-data
  stream.

  ## Flow

  1. Pick a `session_id` — any unique string. It is both the MQTT
     ClientId and the handle the subscribe API uses to find your
     connection.
  2. Connect to `data-api.webull.com:1883` with the app key as username.
     The password is ignored by the server.
  3. Tell Webull which symbols to push with
     `ExWebull.MarketData.Streaming.subscribe/4`.
  4. Subscribe to the MQTT topics you want to receive — see
     `ExWebull.Mqtt.Topics`.

  Each message is decoded by `ExWebull.Mqtt.Message` and fanned out to
  subscriber PIDs as `{:webull_event, topic, decoded}`.

  ## Usage

      {:ok, mqtt} =
        ExWebull.Mqtt.Connection.start_link(
          app_key: "ak",
          session_id: "my-session",
          subscribers: [self()]
        )

      md = ExWebull.Client.new_market_data("ak", "sk")
      ExWebull.MarketData.Streaming.subscribe(md, "my-session", ["AAPL"])
      ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "snapshot")

      receive do
        {:webull_event, "snapshot", {:snapshot, snap}} -> IO.inspect(snap)
      end

  ## Connection rules

  Each app key allows 5 concurrent connections, and reusing a
  `session_id` disconnects the previous connection using it. After a
  disconnect the server holds the slot for about a minute. Subscriptions
  are *not* restored automatically on reconnect — re-subscribe.
  """

  use GenServer
  require Logger

  alias ExWebull.Mqtt.Message

  @type t :: GenServer.server()

  @doc """
  Starts an MQTT connection.

  ## Options

    - `:app_key` (required) — sent as the MQTT username.
    - `:session_id` — MQTT ClientId, also used by
      `ExWebull.MarketData.Streaming.subscribe/4`. Generated if omitted;
      read it back with `session_id/1`.
    - `:host` / `:port` — override the defaults from app config.
    - `:transport` — a Tortoise311 transport module. Defaults to
      Tortoise311.Transport.Tcp; pass Tortoise311.Transport.SSL for TLS.
    - `:subscribers` — initial list of PIDs to receive events.
    - `:name` — register the GenServer under a name.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  @doc "Returns the session id this connection registered with."
  @spec session_id(t()) :: String.t()
  def session_id(conn), do: GenServer.call(conn, :session_id)

  @doc "Adds a subscriber PID to receive `{:webull_event, ...}` messages."
  @spec add_subscriber(t(), pid()) :: :ok
  def add_subscriber(conn, pid \\ self()), do: GenServer.call(conn, {:add_subscriber, pid})

  @doc "Removes a previously-added subscriber."
  @spec remove_subscriber(t(), pid()) :: :ok
  def remove_subscriber(conn, pid \\ self()), do: GenServer.call(conn, {:remove_subscriber, pid})

  @doc """
  Subscribes to MQTT topic(s) — see `ExWebull.Mqtt.Topics` for the list.

  This is the transport-level subscription. Which symbols flow through
  is set by `ExWebull.MarketData.Streaming.subscribe/4`.
  """
  @spec subscribe_topic(t(), String.t() | [String.t()]) :: :ok
  def subscribe_topic(conn, topic_or_topics),
    do: GenServer.call(conn, {:subscribe, List.wrap(topic_or_topics)})

  @doc "Unsubscribes from topic(s)."
  @spec unsubscribe_topic(t(), String.t() | [String.t()]) :: :ok
  def unsubscribe_topic(conn, topic_or_topics),
    do: GenServer.call(conn, {:unsubscribe, List.wrap(topic_or_topics)})

  @doc "Stops the connection."
  @spec stop(t()) :: :ok
  def stop(conn), do: GenServer.stop(conn, :normal)

  # ------------------------------------------------------------------------

  @impl true
  def init(opts) do
    app_key = Keyword.fetch!(opts, :app_key)
    session_id = Keyword.get(opts, :session_id) || generate_session_id()
    {default_host, default_port} = ExWebull.Client.mqtt_endpoint()
    host = Keyword.get(opts, :host, default_host)
    port = Keyword.get(opts, :port, default_port)
    transport = Keyword.get(opts, :transport, Tortoise311.Transport.Tcp)
    subscribers = Keyword.get(opts, :subscribers, []) |> MapSet.new()

    handler_ref = make_ref()

    connect_opts = [
      client_id: session_id,
      user_name: app_key,
      password: app_key,
      server: {transport, server_opts(transport, host, port)},
      handler: {ExWebull.Mqtt.Handler, [owner: self(), ref: handler_ref]},
      subscriptions: []
    ]

    case Tortoise311.Connection.start_link(connect_opts) do
      {:ok, _pid} ->
        {:ok,
         %{
           session_id: session_id,
           subscribers: subscribers,
           topics: MapSet.new(),
           handler_ref: handler_ref
         }}

      {:error, reason} ->
        {:stop, {:mqtt_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call(:session_id, _from, state), do: {:reply, state.session_id, state}

  def handle_call({:add_subscriber, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  def handle_call({:remove_subscriber, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: MapSet.delete(state.subscribers, pid)}}
  end

  def handle_call({:subscribe, topics}, _from, %{session_id: sid} = state) do
    for t <- topics, do: Tortoise311.Connection.subscribe(sid, t, qos: 0)
    {:reply, :ok, %{state | topics: Enum.into(topics, state.topics)}}
  end

  def handle_call({:unsubscribe, topics}, _from, %{session_id: sid} = state) do
    for t <- topics, do: Tortoise311.Connection.unsubscribe(sid, t)
    new_topics = Enum.reduce(topics, state.topics, &MapSet.delete(&2, &1))
    {:reply, :ok, %{state | topics: new_topics}}
  end

  @impl true
  def handle_info({:webull_mqtt_message, topic, payload}, state) do
    case Message.decode(topic, payload) do
      {:ok, topic, decoded} ->
        fanout(state.subscribers, {:webull_event, topic, decoded})

      {:error, reason} ->
        Logger.warning("ExWebull.Mqtt.Connection: undecodable message: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("ExWebull.Mqtt.Connection unexpected: #{inspect(msg)}")
    {:noreply, state}
  end

  defp server_opts(Tortoise311.Transport.SSL, host, port),
    do: [host: String.to_charlist(host), port: port, verify: :verify_none]

  defp server_opts(_tcp, host, port),
    do: [host: String.to_charlist(host), port: port]

  defp fanout(pids, msg) do
    for pid <- pids, is_pid(pid), Process.alive?(pid), do: send(pid, msg)
    :ok
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
