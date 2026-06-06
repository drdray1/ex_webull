defmodule ExWebull.ProtoTest do
  use ExUnit.Case, async: true

  alias ExWebull.Proto.Message
  alias ExWebull.Proto.Quote
  alias ExWebull.Proto.Gateway
  alias ExWebull.Proto.Events

  describe "MQTT market push messages" do
    test "Snapshot round-trips through protobuf" do
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
        change_ratio: "0.70"
      }

      encoded = Message.Snapshot.encode(snapshot)
      decoded = Message.Snapshot.decode(encoded)

      assert decoded.basic.symbol == "AAPL"
      assert decoded.price == "180.50"
      assert decoded.change_ratio == "0.70"
    end

    test "Quote with nested asks/bids round-trips" do
      quote_msg = %Message.Quote{
        basic: %Message.Basic{symbol: "AAPL", instrument_id: "123", timestamp: "100"},
        asks: [%Message.AskBid{price: "181.00", size: "100"}],
        bids: [%Message.AskBid{price: "180.00", size: "200"}]
      }

      encoded = Message.Quote.encode(quote_msg)
      decoded = Message.Quote.decode(encoded)

      assert [%Message.AskBid{price: "181.00", size: "100"}] = decoded.asks
      assert [%Message.AskBid{price: "180.00", size: "200"}] = decoded.bids
    end

    test "Tick round-trips" do
      tick = %Message.Tick{
        basic: %Message.Basic{symbol: "AAPL"},
        time: "100",
        price: "180.50",
        volume: "100",
        side: "B"
      }

      decoded = tick |> Message.Tick.encode() |> Message.Tick.decode()
      assert decoded.side == "B"
      assert decoded.price == "180.50"
    end
  end

  describe "gRPC quote messages" do
    test "InstrumentRequest/Response round-trip" do
      req = %Quote.InstrumentRequest{symbols: "AAPL,TSLA", category: "US_STOCK"}
      decoded = req |> Quote.InstrumentRequest.encode() |> Quote.InstrumentRequest.decode()
      assert decoded.symbols == "AAPL,TSLA"
      assert decoded.category == "US_STOCK"

      resp = %Quote.InstrumentResponse{
        result: [%Quote.Instrument{name: "Apple", symbol: "AAPL", instrument_id: "1"}]
      }

      decoded_resp =
        resp |> Quote.InstrumentResponse.encode() |> Quote.InstrumentResponse.decode()

      assert [%Quote.Instrument{symbol: "AAPL"}] = decoded_resp.result
    end

    test "BatchBarsRequest with int32 count and repeated fields" do
      req = %Quote.BatchBarsRequest{
        symbols: ["AAPL", "TSLA"],
        category: "US_STOCK",
        timespan: "m1",
        count: 100,
        trading_sessions: ["REGULAR", "PRE_MARKET"]
      }

      decoded = req |> Quote.BatchBarsRequest.encode() |> Quote.BatchBarsRequest.decode()
      assert decoded.symbols == ["AAPL", "TSLA"]
      assert decoded.count == 100
      assert decoded.trading_sessions == ["REGULAR", "PRE_MARKET"]
    end

    test "TokenResponse round-trips" do
      r = %Quote.TokenResponse{token: "abc-123"}
      assert r |> Quote.TokenResponse.encode() |> Quote.TokenResponse.decode() == r
    end
  end

  describe "gateway envelope" do
    test "ClientRequest with payload bytes round-trips" do
      inner_bytes =
        %Quote.InstrumentRequest{symbols: "AAPL", category: "US_STOCK"}
        |> Quote.InstrumentRequest.encode()
        |> IO.iodata_to_binary()

      req = %Gateway.ClientRequest{
        type: :Payload,
        requestId: "req-1",
        path: "/instrument/list",
        payload: inner_bytes
      }

      decoded = req |> Gateway.ClientRequest.encode() |> Gateway.ClientRequest.decode()
      assert decoded.type == :Payload
      assert decoded.path == "/instrument/list"
      assert is_binary(decoded.payload)

      inner_decoded = Quote.InstrumentRequest.decode(decoded.payload)
      assert inner_decoded.symbols == "AAPL"
    end
  end

  describe "trade events" do
    test "SubscribeResponse round-trips and decodes event type enum" do
      r = %Events.SubscribeResponse{
        eventType: :SubscribeSuccess,
        subscribeType: 1,
        contentType: "application/json",
        payload: ~s({"status":"ok"}),
        requestId: "req-1",
        timestamp: 1_700_000_000
      }

      decoded = r |> Events.SubscribeResponse.encode() |> Events.SubscribeResponse.decode()
      assert decoded.eventType == :SubscribeSuccess
      assert decoded.subscribeType == 1
      assert decoded.timestamp == 1_700_000_000
    end
  end
end
