defmodule ExWebull.TradeEvents.ConnectionTest do
  @moduledoc """
  Unit tests exercise the GenServer callbacks directly — `init/1`/`open_stream`
  open a live gRPC stream and are left to integration testing.
  """
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ExWebull.Proto.Events.SubscribeResponse
  alias ExWebull.TradeEvents.Connection
  alias ExWebull.TradeEvents.Event

  defp state(overrides \\ %{}) do
    Map.merge(%{subscribers: MapSet.new(), channel: nil}, overrides)
  end

  defp from, do: {self(), make_ref()}

  test "add_subscriber adds the pid" do
    assert {:reply, :ok, new_state} =
             Connection.handle_call({:add_subscriber, self()}, from(), state())

    assert MapSet.member?(new_state.subscribers, self())
  end

  test "remove_subscriber drops the pid" do
    s = state(%{subscribers: MapSet.new([self()])})

    assert {:reply, :ok, new_state} =
             Connection.handle_call({:remove_subscriber, self()}, from(), s)

    refute MapSet.member?(new_state.subscribers, self())
  end

  test "handle_info converts a frame to an Event and fans it out" do
    resp = %SubscribeResponse{
      eventType: :SubscribeSuccess,
      subscribeType: 1,
      contentType: "application/json",
      payload: ~s({"orderId":"ORD-1"}),
      requestId: "REQ-1",
      timestamp: 1_700_000_000
    }

    s = state(%{subscribers: MapSet.new([self()])})

    assert {:noreply, ^s} = Connection.handle_info({:trade_event_frame, resp}, s)

    assert_receive {:webull_trade_event,
                    %Event{event_type: :SubscribeSuccess, payload: %{"orderId" => "ORD-1"}}}
  end

  test "handle_info skips dead subscriber pids" do
    dead = spawn(fn -> :ok end)
    ref = Process.monitor(dead)
    assert_receive {:DOWN, ^ref, :process, ^dead, _}

    resp = %SubscribeResponse{eventType: :Ping, contentType: "text/plain", payload: "ping"}
    s = state(%{subscribers: MapSet.new([dead])})

    assert {:noreply, ^s} = Connection.handle_info({:trade_event_frame, resp}, s)
  end

  test "handle_info stream-closed stops the server" do
    s = state()

    assert capture_log(fn ->
             assert {:stop, :normal, ^s} =
                      Connection.handle_info({:trade_event_stream_closed, :boom}, s)
           end) =~ "stream closed"
  end

  test "handle_info ignores unexpected messages" do
    s = state()
    assert {:noreply, ^s} = Connection.handle_info(:unexpected, s)
  end
end
