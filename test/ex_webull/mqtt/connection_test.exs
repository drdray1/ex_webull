defmodule ExWebull.Mqtt.ConnectionTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias ExWebull.Mqtt.Connection
  alias ExWebull.Proto.Message, as: P

  # `init/1` opens a live socket, so the callbacks are exercised directly
  # against a hand-built state.
  defp state(overrides \\ %{}) do
    Map.merge(
      %{
        session_id: "sess-1",
        subscribers: MapSet.new([self()]),
        topics: MapSet.new(),
        handler_ref: make_ref()
      },
      overrides
    )
  end

  test "session_id/1 reports the registered session" do
    assert {:reply, "sess-1", _} = Connection.handle_call(:session_id, self(), state())
  end

  test "add_subscriber and remove_subscriber update the fanout set" do
    pid = spawn(fn -> :ok end)
    s = state(%{subscribers: MapSet.new()})

    assert {:reply, :ok, s} = Connection.handle_call({:add_subscriber, pid}, self(), s)
    assert MapSet.member?(s.subscribers, pid)

    assert {:reply, :ok, s} = Connection.handle_call({:remove_subscriber, pid}, self(), s)
    refute MapSet.member?(s.subscribers, pid)
  end

  test "subscribe and unsubscribe track topics and call Tortoise" do
    expect(Tortoise311.Connection, :subscribe, 2, fn "sess-1", topic, qos: 0 ->
      send(self(), {:subscribed, topic})
      :ok
    end)

    assert {:reply, :ok, s} =
             Connection.handle_call({:subscribe, ["snapshot", "tick"]}, self(), state())

    assert MapSet.equal?(s.topics, MapSet.new(["snapshot", "tick"]))
    assert_received {:subscribed, "snapshot"}
    assert_received {:subscribed, "tick"}

    expect(Tortoise311.Connection, :unsubscribe, fn "sess-1", "tick" -> :ok end)
    assert {:reply, :ok, s} = Connection.handle_call({:unsubscribe, ["tick"]}, self(), s)
    assert MapSet.equal?(s.topics, MapSet.new(["snapshot"]))
  end

  test "a decodable message is fanned out to subscribers" do
    bytes =
      P.Snapshot.encode(%P.Snapshot{
        basic: %P.Basic{symbol: "AAPL", instrument_id: "1", timestamp: "1"},
        price: "180.50"
      })

    assert {:noreply, _} =
             Connection.handle_info({:webull_mqtt_message, "snapshot", bytes}, state())

    assert_received {:webull_event, "snapshot", {:snapshot, %{price: "180.50"}}}
  end

  test "an undecodable message logs and does not crash" do
    log =
      capture_log(fn ->
        assert {:noreply, _} =
                 Connection.handle_info({:webull_mqtt_message, "notice", "nope"}, state())
      end)

    assert log =~ "undecodable message"
    refute_received {:webull_event, _, _}
  end

  test "unexpected messages are ignored" do
    log =
      capture_log(fn ->
        assert {:noreply, _} = Connection.handle_info(:something_else, state())
      end)

    assert log =~ "unexpected"
  end
end
