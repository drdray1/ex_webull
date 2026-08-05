defmodule ExWebull.MarketData.StreamingTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.MarketData.Streaming

  setup do
    stub = :"streaming_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp body(conn) do
    {:ok, raw, conn} = Plug.Conn.read_body(conn)
    {Jason.decode!(raw), conn}
  end

  test "subscribe/4 applies defaults and wraps a single symbol", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/market-data/streaming/subscribe"
      {payload, conn} = body(conn)
      assert payload["session_id"] == "sess-1"
      assert payload["symbols"] == ["AAPL"]
      assert payload["category"] == "US_STOCK"
      assert payload["sub_types"] == ["SNAPSHOT"]
      assert payload["grab"] == "true"
      refute Map.has_key?(payload, "depth")
      Req.Test.json(conn, %{})
    end)

    assert {:ok, _} = Streaming.subscribe(client, "sess-1", "AAPL")
  end

  test "subscribe/4 forwards explicit sub types and depth", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {payload, conn} = body(conn)
      assert payload["sub_types"] == ["QUOTE", "TICK"]
      assert payload["depth"] == 50
      assert payload["overnight_required"] == true
      Req.Test.json(conn, %{})
    end)

    Streaming.subscribe(client, "sess-1", ["AAPL", "TSLA"],
      sub_types: ["QUOTE", "TICK"],
      depth: 50,
      overnight_required: true
    )
  end

  test "unsubscribe/4 supports unsubscribe_all", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/streaming/unsubscribe"
      {payload, conn} = body(conn)
      assert payload["unsubscribe_all"] == true
      Req.Test.json(conn, %{})
    end)

    Streaming.unsubscribe(client, "sess-1", [], unsubscribe_all: true)
  end

  test "unsubscribe/4 applies defaults when opts are omitted", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {payload, conn} = body(conn)
      assert payload["session_id"] == "sess-1"
      assert payload["symbols"] == ["AAPL"]
      assert payload["category"] == "US_STOCK"
      assert payload["sub_types"] == ["SNAPSHOT"]
      refute Map.has_key?(payload, "unsubscribe_all")
      Req.Test.json(conn, %{})
    end)

    assert {:ok, _} = Streaming.unsubscribe(client, "sess-1", "AAPL")
  end
end
