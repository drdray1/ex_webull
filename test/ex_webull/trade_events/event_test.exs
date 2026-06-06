defmodule ExWebull.TradeEvents.EventTest do
  use ExUnit.Case, async: true

  alias ExWebull.Proto.Events.SubscribeResponse
  alias ExWebull.TradeEvents.Event

  test "from_proto decodes a JSON payload" do
    resp = %SubscribeResponse{
      eventType: :SubscribeSuccess,
      subscribeType: 1,
      contentType: "application/json",
      payload: ~s({"orderId":"ORD-1","status":"FILLED"}),
      requestId: "REQ-1",
      timestamp: 1_700_000_000
    }

    assert %Event{
             event_type: :SubscribeSuccess,
             content_type: "application/json",
             payload: %{"orderId" => "ORD-1", "status" => "FILLED"},
             request_id: "REQ-1",
             timestamp: 1_700_000_000
           } = Event.from_proto(resp)
  end

  test "from_proto passes non-JSON payloads through raw" do
    resp = %SubscribeResponse{
      eventType: :Ping,
      contentType: "text/plain",
      payload: "ping"
    }

    assert %Event{event_type: :Ping, payload: "ping"} = Event.from_proto(resp)
  end

  test "from_proto handles empty payload gracefully" do
    resp = %SubscribeResponse{eventType: :SubscribeSuccess, contentType: "application/json"}
    assert %Event{payload: ""} = Event.from_proto(resp)
  end

  test "from_proto tolerates invalid JSON by returning the raw string" do
    resp = %SubscribeResponse{
      eventType: :SubscribeSuccess,
      contentType: "application/json",
      payload: "not json {"
    }

    assert %Event{payload: "not json {"} = Event.from_proto(resp)
  end
end
