defmodule ExWebull.TradeEvents.Connection do
  @moduledoc """
  GenServer that opens the trade-events gRPC server-streaming RPC and
  forwards each received event to subscribers.

  Subscribers get `{:webull_trade_event, %ExWebull.TradeEvents.Event{}}`
  messages.

  ## Usage

      {:ok, pid} =
        ExWebull.TradeEvents.Connection.start_link(
          app_key: "ak",
          app_secret: "sk",
          accounts: ["ACC-1"],
          subscribers: [self()]
        )

      receive do
        {:webull_trade_event, %ExWebull.TradeEvents.Event{} = ev} ->
          IO.inspect(ev)
      end

  Reconnect is handled by the caller — if the stream closes, the
  process exits normally and supervisors can choose to restart it.
  """

  use GenServer
  require Logger

  alias ExWebull.Proto.Events.{EventService.Stub, SubscribeRequest, SubscribeResponse}
  alias ExWebull.TradeEvents.{Auth, Event}

  @type t :: GenServer.server()

  # ------------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------------

  @doc """
  Starts the trade-events connection.

  ## Options

    - `:app_key` (required)
    - `:app_secret` (required)
    - `:accounts` — list of account ids (required)
    - `:host` / `:port` — override default events gRPC endpoint
    - `:subscribe_type` — defaults to `1` (the only value currently allowed)
    - `:subscribers` — initial PIDs to receive events
    - `:name` — register under a name
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  @doc "Adds a subscriber PID."
  @spec add_subscriber(t(), pid()) :: :ok
  def add_subscriber(pid, subscriber \\ self()),
    do: GenServer.call(pid, {:add_subscriber, subscriber})

  @doc "Removes a subscriber PID."
  @spec remove_subscriber(t(), pid()) :: :ok
  def remove_subscriber(pid, subscriber \\ self()),
    do: GenServer.call(pid, {:remove_subscriber, subscriber})

  @doc "Stops the connection."
  @spec stop(t()) :: :ok
  def stop(pid), do: GenServer.stop(pid, :normal)

  # ------------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------------

  @impl true
  def init(opts) do
    app_key = Keyword.fetch!(opts, :app_key)
    app_secret = Keyword.fetch!(opts, :app_secret)
    accounts = Keyword.fetch!(opts, :accounts)
    {default_host, default_port} = ExWebull.Client.trade_events_endpoint()
    host = Keyword.get(opts, :host, default_host)
    port = Keyword.get(opts, :port, default_port)
    subscribe_type = Keyword.get(opts, :subscribe_type, 1)
    subscribers = Keyword.get(opts, :subscribers, []) |> MapSet.new()

    state = %{
      app_key: app_key,
      app_secret: app_secret,
      accounts: accounts,
      host: host,
      port: port,
      subscribe_type: subscribe_type,
      subscribers: subscribers,
      channel: nil,
      consumer_pid: nil
    }

    case open_stream(state) do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {:stop, {:trade_events_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call({:add_subscriber, pid}, _from, state),
    do: {:reply, :ok, %{state | subscribers: MapSet.put(state.subscribers, pid)}}

  def handle_call({:remove_subscriber, pid}, _from, state),
    do: {:reply, :ok, %{state | subscribers: MapSet.delete(state.subscribers, pid)}}

  @impl true
  def handle_info({:trade_event_frame, %SubscribeResponse{} = resp}, state) do
    event = Event.from_proto(resp)

    for pid <- state.subscribers, is_pid(pid), Process.alive?(pid) do
      send(pid, {:webull_trade_event, event})
    end

    {:noreply, state}
  end

  def handle_info({:trade_event_stream_closed, reason}, state) do
    Logger.warning("ExWebull.TradeEvents.Connection stream closed: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("ExWebull.TradeEvents.Connection unexpected: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.channel, do: GRPC.Stub.disconnect(state.channel)
    :ok
  end

  # ------------------------------------------------------------------------
  # Internals
  # ------------------------------------------------------------------------

  defp open_stream(state) do
    target = "#{state.host}:#{state.port}"
    cred = GRPC.Credential.new(ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get()])

    request = %SubscribeRequest{
      subscribeType: state.subscribe_type,
      timestamp: System.system_time(:millisecond),
      accounts: state.accounts
    }

    payload = SubscribeRequest.encode(request) |> IO.iodata_to_binary()
    metadata = Auth.build_metadata(state.app_key, state.app_secret, payload)

    # grpc 1.0 defaults to the Gun adapter and makes gun an optional dep; we
    # ask for Mint explicitly so the transport matches what we actually pull in.
    with {:ok, channel} <-
           GRPC.Stub.connect(target, cred: cred, adapter: GRPC.Client.Adapters.Mint),
         {:ok, stream} <- Stub.subscribe(channel, request, metadata: metadata) do
      owner = self()
      pid = spawn_link(fn -> consume(stream, owner) end)
      {:ok, %{state | channel: channel, consumer_pid: pid}}
    end
  end

  defp consume(stream, owner) do
    Enum.each(stream, fn
      {:ok, %SubscribeResponse{} = resp} ->
        send(owner, {:trade_event_frame, resp})

      {:error, reason} ->
        send(owner, {:trade_event_stream_closed, reason})
    end)

    send(owner, {:trade_event_stream_closed, :normal})
  catch
    kind, reason ->
      send(owner, {:trade_event_stream_closed, {kind, reason}})
  end
end
