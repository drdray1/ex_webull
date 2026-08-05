defmodule ExWebull.Mqtt.HandlerTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Handler

  test "init/1 keeps owner and ref" do
    ref = make_ref()
    assert {:ok, %{owner: owner, ref: ^ref}} = Handler.init(owner: self(), ref: ref)
    assert owner == self()
  end

  test "handle_message forwards topic and payload to the owner" do
    {:ok, state} = Handler.init(owner: self(), ref: make_ref())

    assert {:ok, ^state} = Handler.handle_message(["snapshot"], <<1, 2, 3>>, state)
    assert_receive {:webull_mqtt_message, "snapshot", <<1, 2, 3>>}
  end

  test "handle_message joins multi-segment topics" do
    {:ok, state} = Handler.init(owner: self(), ref: make_ref())

    assert {:ok, ^state} = Handler.handle_message(["event", "snapshot"], <<0>>, state)
    assert_receive {:webull_mqtt_message, "event/snapshot", <<0>>}
  end

  test "connection/2, subscription/3 and terminate/2 are no-ops" do
    state = %{owner: self(), ref: make_ref()}
    assert {:ok, ^state} = Handler.connection(:up, state)
    assert {:ok, ^state} = Handler.subscription(:up, "snapshot", state)
    assert :ok = Handler.terminate(:normal, state)
  end
end
