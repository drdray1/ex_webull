defmodule ExWebull.Mqtt.TopicsTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Topics

  test "decodes a simple 3-segment topic" do
    assert {:ok, %Topics{instrument_id: "913256135", data_type: 1, interval: 1000}} =
             Topics.decode("913256135-1-1000")
  end

  test "instrument ids containing dashes are preserved" do
    assert {:ok, %Topics{instrument_id: "US-EQ-AAPL", data_type: 2, interval: 0}} =
             Topics.decode("US-EQ-AAPL-2-0")
  end

  test "invalid inputs return :error" do
    assert :error = Topics.decode("")
    assert :error = Topics.decode(nil)
    assert :error = Topics.decode("only-two")
    assert :error = Topics.decode("913256135-abc-100")
  end

  test "encode round-trips decode" do
    {:ok, topic} = Topics.decode("913256135-1-1000")
    assert Topics.encode(topic) == "913256135-1-1000"
  end
end
