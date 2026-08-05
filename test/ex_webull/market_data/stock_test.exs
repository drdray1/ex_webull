defmodule ExWebull.MarketData.StockTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.MarketData.Stock

  setup do
    stub = :"md_stock_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp query(conn), do: URI.decode_query(conn.query_string)

  test "snapshot/3 joins symbols and defaults category", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/snapshot"
      q = query(conn)
      assert q["symbols"] == "AAPL,TSLA"
      assert q["category"] == "US_STOCK"
      assert q["overnight_required"] == "true"
      refute Map.has_key?(q, "extend_hour_required")
      Req.Test.json(conn, [%{"symbol" => "AAPL", "price" => "180.50"}])
    end)

    assert {:ok, [%{"price" => "180.50"}]} =
             Stock.snapshot(client, ["AAPL", "TSLA"], overnight_required: "true")
  end

  test "snapshot/3 honours an explicit category", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert query(conn)["category"] == "US_ETF"
      Req.Test.json(conn, [])
    end)

    Stock.snapshot(client, "SPY", category: "US_ETF")
  end

  test "quotes/3 sends symbol and depth", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/quotes"
      q = query(conn)
      assert q["symbol"] == "AAPL"
      assert q["depth"] == "L2"
      Req.Test.json(conn, %{})
    end)

    Stock.quotes(client, "AAPL", depth: "L2")
  end

  test "tick/3 joins trading sessions", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/tick"
      q = query(conn)
      assert q["count"] == "100"
      assert q["trading_sessions"] == "PRE,RTH"
      Req.Test.json(conn, %{})
    end)

    Stock.tick(client, "AAPL", count: 100, trading_sessions: ["PRE", "RTH"])
  end

  test "bars/4 forwards timespan and time bounds", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/bars"
      q = query(conn)
      assert q["symbol"] == "AAPL"
      assert q["timespan"] == "D"
      assert q["count"] == "30"
      assert q["start_time"] == "1767225600000"
      Req.Test.json(conn, %{"result" => []})
    end)

    Stock.bars(client, "AAPL", "D", count: 30, start_time: 1_767_225_600_000)
  end

  test "batch_bars/4 posts a symbol array", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/market-data/stock/batch-bars"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["symbols"] == ["AAPL", "TSLA"]
      assert payload["timespan"] == "D"
      assert payload["category"] == "US_STOCK"
      refute Map.has_key?(payload, "count")
      Req.Test.json(conn, %{"result" => []})
    end)

    Stock.batch_bars(client, ["AAPL", "TSLA"], "D")
  end

  test "footprint/4 sends granularity and sessions", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/footprint"
      q = query(conn)
      assert q["timespan"] == "M5"
      assert q["trading_sessions"] == "RTH"
      Req.Test.json(conn, %{})
    end)

    Stock.footprint(client, "AAPL", "M5", trading_sessions: "RTH")
  end

  test "noii_snapshot/4 and noii_bars/4 send the imbalance type", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/noii/snapshot"
      assert query(conn)["imbalance_action_type"] == "PRE_OPEN"
      Req.Test.json(conn, %{})
    end)

    Stock.noii_snapshot(client, "AAPL", "PRE_OPEN")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/stock/noii/bars"
      assert query(conn)["imbalance_action_type"] == "PRE_CLOSE"
      Req.Test.json(conn, %{})
    end)

    Stock.noii_bars(client, "AAPL", "PRE_CLOSE")
  end

  test "every function applies its defaults when opts are omitted", %{stub: stub, client: client} do
    calls = [
      {"/openapi/market-data/stock/snapshot", fn -> Stock.snapshot(client, "AAPL") end},
      {"/openapi/market-data/stock/quotes", fn -> Stock.quotes(client, "AAPL") end},
      {"/openapi/market-data/stock/tick", fn -> Stock.tick(client, "AAPL") end},
      {"/openapi/market-data/stock/bars", fn -> Stock.bars(client, "AAPL", "D") end},
      {"/openapi/market-data/stock/footprint", fn -> Stock.footprint(client, "AAPL", "M1") end}
    ]

    for {path, call} <- calls do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        assert URI.decode_query(conn.query_string)["category"] == "US_STOCK"
        Req.Test.json(conn, %{})
      end)

      assert {:ok, _} = call.()
    end
  end
end
