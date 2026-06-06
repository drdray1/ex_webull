defmodule ExWebull.Mqtt.Connection do
  @moduledoc """
  GenServer wrapping `Tortoise311` for Webull's MQTTv3.1.1 market-push
  stream.

  ## Flow

  1. Caller provides a streaming `token` (obtained via
     `ExWebull.Market.Token.get/1`).
  2. Connects to `usquotes-api.webullfintech.com:8883` over TLS.
  3. MQTT CONNECT uses `user_name = password = token`, client id a
     random UUID prefixed with the app key.
  4. Each subscribed topic's payload is decoded by
     `ExWebull.Mqtt.Message` and fanned out to subscriber PIDs as
     `{:webull_event, topic_struct, decoded}`.

  ## Subscription

  This module only handles the MQTT transport — you still need to call
  `ExWebull.Market.Subscribe.subscribe/5` via a gRPC client to tell
  Webull what data to push to you.

  ## Usage

      {:ok, mqtt} =
        ExWebull.Mqtt.Connection.start_link(
          app_key: "ak",
          token: token,
          subscribers: [self()]
        )

      ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "913256135-1-1000")

      receive do
        {:webull_event, topic, {:snapshot, snap}} -> IO.inspect(snap)
      end
  """

  use GenServer
  require Logger

  @type t :: GenServer.server()

  @doc """
  Starts an MQTT connection.

  ## Options
    - `:app_key` (required) — used to derive client id
    - `:token` (required) — streaming token from `ExWebull.Market.Token.get/1`
    - `:host` / `:port` — override defaults
    - `:subscribers` — initial list of PIDs to receive events
    - `:name` — register the GenServer under a name
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  @doc "Adds a subscriber PID to receive `{:webull_event, ...}` messages."
  @spec add_subscriber(t(), pid()) :: :ok
  def add_subscriber(conn, pid \\ self()), do: GenServer.call(conn, {:add_subscriber, pid})

  @doc "Removes a previously-added subscriber."
  @spec remove_subscriber(t(), pid()) :: :ok
  def remove_subscriber(conn, pid \\ self()), do: GenServer.call(conn, {:remove_subscriber, pid})

  @doc "Subscribes to one or more topic strings on the MQTT broker."
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
    token = Keyword.fetch!(opts, :token)
    {default_host, default_port} = ExWebull.Client.mqtt_endpoint()
    host = Keyword.get(opts, :host, default_host)
    port = Keyword.get(opts, :port, default_port)
    subscribers = Keyword.get(opts, :subscribers, []) |> MapSet.new()

    client_id = "#{app_key}_#{generate_suffix()}"
    handler_ref = make_ref()

    connect_opts = [
      client_id: client_id,
      user_name: token,
      password: token,
      server:
        {Tortoise311.Transport.SSL,
         host: String.to_charlist(host), port: port, verify: :verify_none},
      handler: {ExWebull.Mqtt.Handler, [owner: self(), ref: handler_ref]},
      subscriptions: []
    ]

    case Tortoise311.Connection.start_link(connect_opts) do
      {:ok, _pid} ->
        {:ok,
         %{
           client_id: client_id,
           subscribers: subscribers,
           topics: MapSet.new(),
           handler_ref: handler_ref
         }}

      {:error, reason} ->
        {:stop, {:mqtt_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call({:add_subscriber, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  def handle_call({:remove_subscriber, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: MapSet.delete(state.subscribers, pid)}}
  end

  def handle_call({:subscribe, topics}, _from, %{client_id: cid} = state) do
    for t <- topics, do: Tortoise311.Connection.subscribe(cid, t, qos: 0)
    {:reply, :ok, %{state | topics: Enum.into(topics, state.topics)}}
  end

  def handle_call({:unsubscribe, topics}, _from, %{client_id: cid} = state) do
    for t <- topics, do: Tortoise311.Connection.unsubscribe(cid, t)
    new_topics = Enum.reduce(topics, state.topics, &MapSet.delete(&2, &1))
    {:reply, :ok, %{state | topics: new_topics}}
  end

  @impl true
  def handle_info({:webull_mqtt_message, topic, payload}, state) do
    case ExWebull.Mqtt.Message.decode(topic, payload) do
      {:ok, topic_struct, decoded} ->
        fanout(state.subscribers, {:webull_event, topic_struct, decoded})

      {:error, reason} ->
        Logger.warning("ExWebull.Mqtt.Connection: invalid topic #{topic}: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("ExWebull.Mqtt.Connection unexpected: #{inspect(msg)}")
    {:noreply, state}
  end

  defp fanout(pids, msg) do
    for pid <- pids, is_pid(pid), Process.alive?(pid), do: send(pid, msg)
    :ok
  end

  defp generate_suffix do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
