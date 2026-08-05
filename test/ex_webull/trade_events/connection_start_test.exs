defmodule ExWebull.TradeEvents.ConnectionStartTest do
  @moduledoc """
  Exercises `start_link/1`, the stream consumer, and `terminate/2`
  against a mocked gRPC channel, so no connection is opened.

  Mimic runs in global mode because the GenServer and its spawned
  consumer both call into the mocked modules; that requires
  `async: false`.
  """
  use ExUnit.Case, async: false
  use Mimic

  import ExUnit.CaptureLog

  alias ExWebull.Proto.Events.EventService.Stub
  alias ExWebull.Proto.Events.SubscribeResponse
  alias ExWebull.TradeEvents.{Connection, Event}

  setup :set_mimic_global

  @channel :fake_channel

  defp response(payload) do
    %SubscribeResponse{
      eventType: :SubscribeSuccess,
      subscribeType: 1,
      contentType: "application/json",
      payload: payload,
      requestId: "REQ-1",
      timestamp: 1_767_225_600_000
    }
  end

  defp mock_stream(frames) do
    stub(GRPC.Stub, :connect, fn _target, _opts -> {:ok, @channel} end)
    stub(GRPC.Stub, :disconnect, fn @channel -> {:ok, @channel} end)
    stub(Stub, :subscribe, fn @channel, _req, _opts -> {:ok, frames} end)
  end

  # A stream that never yields, so the consumer stays alive and the
  # connection stays up for the duration of the test.
  defp open_stream, do: Stream.map([1], fn _ -> Process.sleep(:infinity) end)

  defp start(opts \\ []) do
    Connection.start_link(
      Keyword.merge(
        [app_key: "ak", app_secret: "sk", accounts: ["ACC-1"], subscribers: [self()]],
        opts
      )
    )
  end

  test "start_link/1 opens the stream and fans out each frame" do
    mock_stream([{:ok, response(~s({"orderId":"ORD-1"}))}])

    {:ok, conn} = start()

    assert_receive {:webull_trade_event,
                    %Event{event_type: :SubscribeSuccess, payload: %{"orderId" => "ORD-1"}}}

    # The consumer signals normal closure once the stream is exhausted,
    # which stops the connection.
    ref = Process.monitor(conn)
    assert_receive {:DOWN, ^ref, :process, ^conn, :normal}, 1_000
  end

  test "start_link/1 passes the subscribed accounts and subscribe type through" do
    test = self()

    stub(GRPC.Stub, :connect, fn target, _opts ->
      send(test, {:target, target})
      {:ok, @channel}
    end)

    stub(GRPC.Stub, :disconnect, fn @channel -> {:ok, @channel} end)

    stub(Stub, :subscribe, fn @channel, req, opts ->
      send(test, {:request, req, opts})
      {:ok, []}
    end)

    {:ok, _conn} = start(accounts: ["ACC-1", "ACC-2"], subscribe_type: 1)

    assert_receive {:target, "events-api.webull.com:443"}
    assert_receive {:request, req, opts}
    assert req.accounts == ["ACC-1", "ACC-2"]
    assert req.subscribeType == 1

    # The RPC is signed the same way HTTP requests are.
    metadata = opts[:metadata]
    assert metadata["x-app-key"] == "ak"
    assert metadata["x-signature"] != ""
    assert metadata["x-signature-algorithm"] == "HMAC-SHA1"
  end

  test "start_link/1 honours host and port overrides" do
    test = self()

    stub(GRPC.Stub, :connect, fn target, _opts ->
      send(test, {:target, target})
      {:ok, @channel}
    end)

    stub(GRPC.Stub, :disconnect, fn @channel -> {:ok, @channel} end)
    stub(Stub, :subscribe, fn @channel, _req, _opts -> {:ok, []} end)

    {:ok, _conn} = start(host: "events.example.test", port: 9443)
    assert_receive {:target, "events.example.test:9443"}
  end

  test "start_link/1 stops when the channel cannot be opened" do
    stub(GRPC.Stub, :connect, fn _target, _opts -> {:error, :econnrefused} end)
    Process.flag(:trap_exit, true)

    assert {:error, {:trade_events_connect_failed, :econnrefused}} = start()
  end

  test "start_link/1 stops when the subscribe RPC is rejected" do
    stub(GRPC.Stub, :connect, fn _target, _opts -> {:ok, @channel} end)
    stub(GRPC.Stub, :disconnect, fn @channel -> {:ok, @channel} end)
    stub(Stub, :subscribe, fn @channel, _req, _opts -> {:error, :unauthenticated} end)
    Process.flag(:trap_exit, true)

    assert {:error, {:trade_events_connect_failed, :unauthenticated}} = start()
  end

  test "an error frame closes the stream" do
    mock_stream([{:error, :stream_reset}])

    log =
      capture_log(fn ->
        {:ok, conn} = start()
        ref = Process.monitor(conn)
        assert_receive {:DOWN, ^ref, :process, ^conn, :normal}, 1_000
      end)

    assert log =~ "stream closed"
  end

  test "a raising stream is reported as a closure rather than crashing" do
    stub(GRPC.Stub, :connect, fn _target, _opts -> {:ok, @channel} end)
    stub(GRPC.Stub, :disconnect, fn @channel -> {:ok, @channel} end)

    stub(Stub, :subscribe, fn @channel, _req, _opts ->
      {:ok, Stream.map([1], fn _ -> throw(:boom) end)}
    end)

    log =
      capture_log(fn ->
        {:ok, conn} = start()
        ref = Process.monitor(conn)
        assert_receive {:DOWN, ^ref, :process, ^conn, :normal}, 1_000
      end)

    assert log =~ "stream closed"
  end

  test "add_subscriber/2, remove_subscriber/2 and a registered name" do
    mock_stream(open_stream())
    name = :"trade_events_#{System.unique_integer([:positive])}"

    {:ok, conn} = start(name: name, subscribers: [])
    assert :ok = Connection.add_subscriber(name)
    assert :ok = Connection.remove_subscriber(name)

    Process.unlink(conn)
    Connection.stop(name)
  end

  test "terminate/2 disconnects an open channel" do
    test = self()

    stub(GRPC.Stub, :disconnect, fn @channel ->
      send(test, :disconnected)
      {:ok, @channel}
    end)

    assert :ok = Connection.terminate(:normal, %{channel: @channel})
    assert_received :disconnected

    assert :ok = Connection.terminate(:normal, %{channel: nil})
    refute_received :disconnected
  end
end
