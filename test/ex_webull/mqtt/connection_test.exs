defmodule ExWebull.Mqtt.ConnectionTest do
  @moduledoc """
  Unit tests exercise the GenServer callbacks directly with a hand-built
  state — `init/1` opens a live TLS socket, so it is not covered here.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Mqtt.Connection
  alias ExWebull.Proto.Message, as: P

  defp state(overrides \\ %{}) do
    Map.merge(
      %{
        client_id: "ak_abc",
        subscribers: MapSet.new(),
        topics: MapSet.new(),
        handler_ref: make_ref()
      },
      overrides
    )
  end

  defp from, do: {self(), make_ref()}

  test "add_subscriber adds the pid to state" do
    assert {:reply, :ok, new_state} =
             Connection.handle_call({:add_subscriber, self()}, from(), state())

    assert MapSet.member?(new_state.subscribers, self())
  end

  test "remove_subscriber drops the pid from state" do
    s = state(%{subscribers: MapSet.new([self()])})

    assert {:reply, :ok, new_state} =
             Connection.handle_call({:remove_subscriber, self()}, from(), s)

    refute MapSet.member?(new_state.subscribers, self())
  end

  test "subscribe records topics and calls Tortoise" do
    stub(Tortoise311.Connection, :subscribe, fn "ak_abc", _topic, qos: 0 -> {:ok, make_ref()} end)

    assert {:reply, :ok, new_state} =
             Connection.handle_call({:subscribe, ["913256135-1-1000"]}, from(), state())

    assert MapSet.member?(new_state.topics, "913256135-1-1000")
  end

  test "unsubscribe removes topics and calls Tortoise" do
    stub(Tortoise311.Connection, :unsubscribe, fn "ak_abc", _topic -> {:ok, make_ref()} end)
    s = state(%{topics: MapSet.new(["913256135-1-1000"])})

    assert {:reply, :ok, new_state} =
             Connection.handle_call({:unsubscribe, ["913256135-1-1000"]}, from(), s)

    refute MapSet.member?(new_state.topics, "913256135-1-1000")
  end

  test "handle_info fans a decoded snapshot out to subscribers" do
    snap = %P.Snapshot{basic: %P.Basic{symbol: "AAPL"}, price: "180.50"}
    payload = P.Snapshot.encode(snap) |> IO.iodata_to_binary()
    s = state(%{subscribers: MapSet.new([self()])})

    assert {:noreply, ^s} =
             Connection.handle_info({:webull_mqtt_message, "123-1-1000", payload}, s)

    assert_receive {:webull_event, %ExWebull.Mqtt.Topics{data_type: 1}, {:snapshot, decoded}}
    assert decoded.price == "180.50"
  end

  test "handle_info skips dead subscriber pids without crashing" do
    dead = spawn(fn -> :ok end)
    ref = Process.monitor(dead)
    assert_receive {:DOWN, ^ref, :process, ^dead, _}

    snap = %P.Snapshot{basic: %P.Basic{symbol: "AAPL"}, price: "1"}
    payload = P.Snapshot.encode(snap) |> IO.iodata_to_binary()
    s = state(%{subscribers: MapSet.new([dead])})

    assert {:noreply, ^s} =
             Connection.handle_info({:webull_mqtt_message, "123-1-1000", payload}, s)
  end

  test "handle_info on an invalid topic is a no-op" do
    s = state()
    assert {:noreply, ^s} = Connection.handle_info({:webull_mqtt_message, "bad", <<>>}, s)
    refute_receive {:webull_event, _, _}
  end

  test "handle_info ignores unexpected messages" do
    s = state()
    assert {:noreply, ^s} = Connection.handle_info(:something_else, s)
  end
end
