defmodule ExWebull.Mqtt.MessageTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Message
  alias ExWebull.Proto.Message, as: P

  defp basic, do: %P.Basic{symbol: "AAPL", instrument_id: "913256135", timestamp: "100"}

  test "decodes a snapshot payload including overnight fields" do
    bytes =
      P.Snapshot.encode(%P.Snapshot{
        basic: basic(),
        price: "180.50",
        ovn_price: "181.00",
        ovn_change_ratio: "0.28"
      })

    assert {:ok, "snapshot", {:snapshot, snap}} = Message.decode("snapshot", bytes)
    assert snap.basic.symbol == "AAPL"
    assert snap.price == "180.50"
    assert snap.ovn_price == "181.00"
    assert snap.ovn_change_ratio == "0.28"
  end

  test "decodes quote and tick payloads" do
    quote_bytes =
      P.Quote.encode(%P.Quote{
        basic: basic(),
        asks: [%P.AskBid{price: "181.00", size: "100"}],
        bids: [%P.AskBid{price: "180.00", size: "200"}]
      })

    assert {:ok, "quote", {:quote, q}} = Message.decode("quote", quote_bytes)
    assert [%{price: "181.00"}] = q.asks

    tick_bytes = P.Tick.encode(%P.Tick{basic: basic(), price: "180.50", side: "BUY"})
    assert {:ok, "tick", {:tick, t}} = Message.decode("tick", tick_bytes)
    assert t.side == "BUY"
  end

  test "decodes event contract payloads" do
    quote_bytes =
      P.EventQuote.encode(%P.EventQuote{
        basic: basic(),
        yes_bids: [%P.EventAskBid{price: "0.62", size: "10"}],
        no_bids: [%P.EventAskBid{price: "0.38", size: "12"}]
      })

    assert {:ok, "event-quote", {:event_quote, q}} = Message.decode("event-quote", quote_bytes)
    assert [%{price: "0.62"}] = q.yes_bids

    snap_bytes =
      P.EventSnapshot.encode(%P.EventSnapshot{basic: basic(), yes_bid: "0.62", no_ask: "0.39"})

    assert {:ok, _, {:event_snapshot, s}} = Message.decode("event-snapshot", snap_bytes)
    assert s.yes_bid == "0.62"

    tick_bytes =
      P.EventTick.encode(%P.EventTick{basic: basic(), yes_price: "0.62", trade_id: "T-1"})

    assert {:ok, _, {:event_tick, t}} = Message.decode("event-tick", tick_bytes)
    assert t.trade_id == "T-1"
  end

  test "decodes notice as JSON and echo as a heartbeat" do
    notice = Jason.encode!(%{"type" => "status", "rtt" => 100, "drop" => 0, "sent" => 0})

    assert {:ok, "notice", {:notice, %{"type" => "status", "rtt" => 100}}} =
             Message.decode("notice", notice)

    assert {:ok, "echo", :echo} = Message.decode("echo", "")
  end

  test "an unknown topic returns raw bytes rather than an error" do
    assert {:ok, "brand-new", {:unknown, "brand-new", "raw"}} =
             Message.decode("brand-new", "raw")
  end

  test "an undecodable payload returns an error tuple" do
    assert {:error, {:invalid_payload, "notice", _}} = Message.decode("notice", "not json")
  end
end
