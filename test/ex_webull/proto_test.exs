defmodule ExWebull.ProtoTest do
  use ExUnit.Case, async: true

  alias ExWebull.Proto.Events
  alias ExWebull.Proto.Message

  describe "MQTT market push messages" do
    test "Snapshot round-trips including extended and overnight sessions" do
      snapshot = %Message.Snapshot{
        basic: %Message.Basic{symbol: "AAPL", instrument_id: "123", timestamp: "100"},
        trade_time: "2026-04-22T15:30:00Z",
        price: "180.50",
        open: "178.00",
        high: "182.00",
        low: "177.50",
        pre_close: "179.25",
        volume: "1000000",
        change: "1.25",
        change_ratio: "0.70",
        ext_price: "180.90",
        ovn_price: "181.10",
        ovn_volume: "5000"
      }

      decoded = snapshot |> Message.Snapshot.encode() |> Message.Snapshot.decode()

      assert decoded.basic.symbol == "AAPL"
      assert decoded.price == "180.50"
      assert decoded.ext_price == "180.90"
      assert decoded.ovn_price == "181.10"
      assert decoded.ovn_volume == "5000"
    end

    test "Quote with nested asks/bids round-trips" do
      quote_msg = %Message.Quote{
        basic: %Message.Basic{symbol: "AAPL", instrument_id: "123", timestamp: "100"},
        asks: [%Message.AskBid{price: "181.00", size: "100"}],
        bids: [%Message.AskBid{price: "180.00", size: "200"}]
      }

      decoded = quote_msg |> Message.Quote.encode() |> Message.Quote.decode()

      assert [%Message.AskBid{price: "181.00"}] = decoded.asks
      assert [%Message.AskBid{price: "180.00"}] = decoded.bids
    end

    test "Quote asks carry per-order and per-broker detail" do
      ask = %Message.AskBid{
        price: "181.00",
        size: "100",
        order: [%Message.Order{mpid: "NSDQ", size: "50"}],
        broker: [%Message.Broker{bid: "B1", name: "Broker One"}]
      }

      decoded =
        %Message.Quote{asks: [ask]} |> Message.Quote.encode() |> Message.Quote.decode()

      assert [%{order: [%{mpid: "NSDQ"}], broker: [%{name: "Broker One"}]}] = decoded.asks
    end

    test "Tick round-trips" do
      tick = %Message.Tick{
        basic: %Message.Basic{symbol: "AAPL", instrument_id: "123", timestamp: "100"},
        time: "100",
        price: "180.50",
        volume: "100",
        side: "BUY"
      }

      decoded = tick |> Message.Tick.encode() |> Message.Tick.decode()
      assert decoded.side == "BUY"
      assert decoded.basic.instrument_id == "123"
    end
  end

  describe "event contract push messages" do
    test "EventQuote splits yes and no bids" do
      msg = %Message.EventQuote{
        basic: %Message.Basic{symbol: "EVT", instrument_id: "9", timestamp: "1"},
        yes_bids: [%Message.EventAskBid{price: "0.62", size: "10"}],
        no_bids: [%Message.EventAskBid{price: "0.38", size: "12"}]
      }

      decoded = msg |> Message.EventQuote.encode() |> Message.EventQuote.decode()
      assert [%{price: "0.62"}] = decoded.yes_bids
      assert [%{price: "0.38"}] = decoded.no_bids
    end

    test "EventSnapshot round-trips both sides of the book" do
      msg = %Message.EventSnapshot{
        basic: %Message.Basic{symbol: "EVT", instrument_id: "9", timestamp: "1"},
        price: "0.62",
        open_interest: "1200",
        yes_ask: "0.63",
        yes_bid: "0.62",
        no_ask: "0.39",
        no_bid: "0.37"
      }

      decoded = msg |> Message.EventSnapshot.encode() |> Message.EventSnapshot.decode()
      assert decoded.open_interest == "1200"
      assert decoded.yes_ask == "0.63"
      assert decoded.no_bid == "0.37"
    end

    test "EventTick round-trips" do
      msg = %Message.EventTick{
        basic: %Message.Basic{symbol: "EVT", instrument_id: "9", timestamp: "1"},
        yes_price: "0.62",
        no_price: "0.38",
        volume: "5",
        side: "BUY",
        trade_id: "T-1",
        time: "100"
      }

      decoded = msg |> Message.EventTick.encode() |> Message.EventTick.decode()
      assert decoded.trade_id == "T-1"
      assert decoded.yes_price == "0.62"
    end
  end

  describe "trade events" do
    test "SubscribeRequest round-trips" do
      req = %Events.SubscribeRequest{
        subscribeType: 1,
        timestamp: 1_767_225_600_000,
        contentType: "application/json",
        payload: "{}",
        accounts: ["ACC-1", "ACC-2"]
      }

      decoded = req |> Events.SubscribeRequest.encode() |> Events.SubscribeRequest.decode()
      assert decoded.accounts == ["ACC-1", "ACC-2"]
      assert decoded.subscribeType == 1
    end

    test "SubscribeResponse carries a typed event and JSON payload" do
      resp = %Events.SubscribeResponse{
        eventType: :Ping,
        subscribeType: 1,
        contentType: "application/json",
        payload: ~s({"status":"FILLED"}),
        requestId: "REQ-1",
        timestamp: 1_767_225_600_000
      }

      decoded = resp |> Events.SubscribeResponse.encode() |> Events.SubscribeResponse.decode()
      assert decoded.eventType == :Ping
      assert decoded.payload == ~s({"status":"FILLED"})
    end
  end
end
