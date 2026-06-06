defmodule ExWebull.Mqtt.HandlerTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Handler

  test "init/1 keeps owner and ref" do
    ref = make_ref()
    assert {:ok, %{owner: owner, ref: ^ref}} = Handler.init(owner: self(), ref: ref)
    assert owner == self()
  end

  test "handle_message forwards joined topic and payload to the owner" do
    {:ok, state} = Handler.init(owner: self(), ref: make_ref())

    assert {:ok, ^state} =
             Handler.handle_message(["913256135", "1", "1000"], <<1, 2, 3>>, state)

    assert_receive {:webull_mqtt_message, "913256135/1/1000", <<1, 2, 3>>}
  end

  test "connection/2, subscription/3 and terminate/2 are no-ops" do
    state = %{owner: self(), ref: make_ref()}
    assert {:ok, ^state} = Handler.connection(:up, state)
    assert {:ok, ^state} = Handler.subscription(:up, "913256135-1-1000", state)
    assert :ok = Handler.terminate(:normal, state)
  end
end
