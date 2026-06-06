defmodule ExWebull.Mqtt.MessageTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Message
  alias ExWebull.Mqtt.Topics
  alias ExWebull.Proto.Message, as: P

  test "decodes a snapshot payload at data_type=1" do
    snap = %P.Snapshot{
      basic: %P.Basic{symbol: "AAPL", instrument_id: "123", timestamp: "t"},
      price: "180.50",
      volume: "1000"
    }

    payload = P.Snapshot.encode(snap) |> IO.iodata_to_binary()

    assert {:ok, %Topics{data_type: 1}, {:snapshot, decoded}} =
             Message.decode("123-1-1000", payload)

    assert decoded.price == "180.50"
  end

  test "decodes a quote payload at data_type=0" do
    q = %P.Quote{
      basic: %P.Basic{symbol: "AAPL"},
      asks: [%P.AskBid{price: "181", size: "100"}]
    }

    payload = P.Quote.encode(q) |> IO.iodata_to_binary()

    assert {:ok, _, {:quote, decoded}} = Message.decode("123-0-0", payload)
    assert [%P.AskBid{price: "181"}] = decoded.asks
  end

  test "decodes a tick payload at data_type=2" do
    t = %P.Tick{basic: %P.Basic{symbol: "AAPL"}, time: "1", price: "2", volume: "3", side: "B"}
    payload = P.Tick.encode(t) |> IO.iodata_to_binary()

    assert {:ok, _, {:tick, decoded}} = Message.decode("123-2-0", payload)
    assert decoded.side == "B"
  end

  test "unknown data_type falls through to {:unknown, ...}" do
    assert {:ok, _, {:unknown, 9, <<1, 2, 3>>}} = Message.decode("x-9-0", <<1, 2, 3>>)
  end

  test "invalid topic returns error" do
    assert {:error, {:invalid_topic, "bad"}} = Message.decode("bad", <<>>)
  end
end
