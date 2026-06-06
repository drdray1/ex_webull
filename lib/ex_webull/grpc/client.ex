defmodule ExWebull.Grpc.Client do
  @moduledoc """
  GenServer that owns the bidirectional gRPC stream used by Webull's
  Quote gateway. It authenticates each request with
  `ExWebull.Grpc.Auth` metadata and correlates responses by
  `requestId`.

  ## Lifecycle

      {:ok, pid} = ExWebull.Grpc.Client.start_link(
        app_key: "ak", app_secret: "sk"
      )

      {:ok, %SnapshotResponse{} = resp} =
        ExWebull.Grpc.Client.request(
          pid,
          "/market-data/snapshot",
          request_msg,
          ExWebull.Proto.Quote.SnapshotRequest,
          ExWebull.Proto.Quote.SnapshotResponse
        )

  ## State machine

  The client keeps a map of `request_id -> from`, so `request/5` can
  block the caller until the matching response arrives. Ping/pong is
  handled internally (echo on receipt).

  ## Untested caveat

  This module is structurally complete but has not been exercised
  against a live Webull gRPC endpoint — integration testing requires
  valid credentials and an activated market subscription.
  """

  use GenServer
  require Logger

  alias ExWebull.Proto.Gateway
  alias ExWebull.Proto.Gateway.Quote.Stub, as: QuoteStub

  @type t :: GenServer.server()
  @default_timeout 15_000

  # ------------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------------

  @doc """
  Starts the client.

  ## Options

    - `:app_key` (required) — Webull app key
    - `:app_secret` (required) — Webull app secret
    - `:host` / `:port` — override default quotes gRPC endpoint
    - `:name` — register a name for the GenServer
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  @doc """
  Makes a gRPC request/response call.

  Encodes `request_struct` with `request_module`, wraps it in a
  `ClientRequest`, sends it over the stream, and waits for the
  matching `ClientResponse`. Decodes the payload with `response_module`
  and returns `{:ok, decoded}` on success, or `{:error, reason}`.
  """
  @spec request(t(), String.t(), struct(), module(), module(), pos_integer()) ::
          {:ok, struct()} | {:error, term()}
  def request(
        client,
        path,
        request_struct,
        request_module,
        response_module,
        timeout \\ @default_timeout
      ) do
    payload = request_module.encode(request_struct) |> IO.iodata_to_binary()

    GenServer.call(
      client,
      {:request, path, payload, response_module, timeout},
      timeout + 1_000
    )
  end

  @doc "Sends a bare Ping frame. Mostly for keep-alive."
  @spec ping(t()) :: :ok | {:error, term()}
  def ping(client), do: GenServer.call(client, :ping)

  @doc "Stops the client and closes the gRPC stream."
  @spec stop(t()) :: :ok
  def stop(client), do: GenServer.stop(client, :normal)

  # ------------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------------

  @impl true
  def init(opts) do
    app_key = Keyword.fetch!(opts, :app_key)
    app_secret = Keyword.fetch!(opts, :app_secret)
    {default_host, default_port} = ExWebull.Client.quotes_grpc_endpoint()
    host = Keyword.get(opts, :host, default_host)
    port = Keyword.get(opts, :port, default_port)

    state = %{
      app_key: app_key,
      app_secret: app_secret,
      host: host,
      port: port,
      channel: nil,
      stream: nil,
      pending: %{}
    }

    case connect(state) do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {:stop, {:grpc_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call({:request, path, payload, response_module, _timeout}, from, state) do
    request_id = generate_request_id()

    req = %Gateway.ClientRequest{
      type: :Payload,
      requestId: request_id,
      path: path,
      payload: payload
    }

    case send_frame(state, req) do
      :ok ->
        state = put_in(state.pending[request_id], {from, response_module})
        {:noreply, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:ping, _from, state) do
    pong = %Gateway.ClientRequest{
      type: :Ping,
      requestId: generate_request_id(),
      path: "",
      payload: ""
    }

    reply =
      case send_frame(state, pong) do
        :ok -> :ok
        err -> err
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_info({:grpc_frame, %Gateway.ClientResponse{} = resp}, state) do
    handle_response(resp, state)
  end

  def handle_info({:grpc_stream_closed, reason}, state) do
    Logger.warning("ExWebull.Grpc.Client stream closed: #{inspect(reason)}")
    # Notify all pending callers
    for {_rid, {from, _mod}} <- state.pending do
      GenServer.reply(from, {:error, {:stream_closed, reason}})
    end

    {:stop, :normal, %{state | pending: %{}}}
  end

  def handle_info(msg, state) do
    Logger.debug("ExWebull.Grpc.Client unexpected msg: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.channel, do: GRPC.Stub.disconnect(state.channel)
    :ok
  end

  # ------------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------------

  defp connect(state) do
    target = "#{state.host}:#{state.port}"
    cred = GRPC.Credential.new(ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get()])

    with {:ok, channel} <- GRPC.Stub.connect(target, cred: cred),
         metadata = auth_metadata(state, nil, nil),
         stream = QuoteStub.stream_request(channel, metadata: metadata) do
      owner = self()
      spawn_link(fn -> consume_stream(stream, owner) end)
      {:ok, %{state | channel: channel, stream: stream}}
    end
  end

  defp consume_stream(stream, owner) do
    try do
      stream
      |> GRPC.Stub.recv()
      |> case do
        {:ok, recv_stream} -> forward_frames(recv_stream, owner)
        {:error, reason} -> send(owner, {:grpc_stream_closed, reason})
      end
    catch
      kind, reason -> send(owner, {:grpc_stream_closed, {kind, reason}})
    end
  end

  defp forward_frames(recv_stream, owner) do
    Enum.each(recv_stream, fn
      {:ok, %Gateway.ClientResponse{} = frame} -> send(owner, {:grpc_frame, frame})
      {:error, reason} -> send(owner, {:grpc_stream_closed, reason})
    end)

    send(owner, {:grpc_stream_closed, :normal})
  end

  defp send_frame(state, %Gateway.ClientRequest{path: path, payload: payload} = req) do
    metadata = auth_metadata(state, path, payload)

    try do
      GRPC.Stub.send_request(state.stream, req, metadata: metadata)
      :ok
    rescue
      e -> {:error, e}
    end
  end

  defp auth_metadata(state, path, payload) do
    ExWebull.Grpc.Auth.build_metadata(
      state.app_key,
      state.app_secret,
      state.host,
      path || "",
      payload
    )
  end

  defp handle_response(%Gateway.ClientResponse{type: :Ping} = resp, state) do
    pong = %Gateway.ClientRequest{
      type: :Pong,
      requestId: resp.requestId,
      path: "",
      payload: ""
    }

    _ = send_frame(state, pong)
    {:noreply, state}
  end

  defp handle_response(%Gateway.ClientResponse{type: :Pong}, state), do: {:noreply, state}

  defp handle_response(%Gateway.ClientResponse{requestId: rid} = resp, state) do
    case Map.pop(state.pending, rid) do
      {nil, _} ->
        Logger.debug("gRPC frame with unknown requestId #{rid}")
        {:noreply, state}

      {{from, mod}, rest} ->
        reply = decode_reply(resp, mod)
        GenServer.reply(from, reply)
        {:noreply, %{state | pending: rest}}
    end
  end

  defp decode_reply(%Gateway.ClientResponse{code: code, msg: msg}, _mod) when code >= 400 do
    {:error, {:api_error, code, msg}}
  end

  defp decode_reply(%Gateway.ClientResponse{payload: payload}, module) do
    try do
      {:ok, module.decode(payload)}
    rescue
      e -> {:error, {:decode_failed, e}}
    end
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower)
  end
end
