defmodule ExWebull.MarketDataTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"mdata_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "snapshot/3 forwards symbols and category", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/market-data/snapshot"
      q = conn.query_string
      assert q =~ "symbols=AAPL"
      assert q =~ "category=US_STOCK"
      Req.Test.json(conn, %{"result" => []})
    end)

    assert {:ok, _} = ExWebull.MarketData.snapshot(client, "AAPL", "US_STOCK")
  end

  test "bars/5 forwards count and trading_sessions", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/market-data/bars"
      q = conn.query_string
      assert q =~ "symbol=AAPL"
      assert q =~ "category=US_STOCK"
      assert q =~ "timespan=m1"
      assert q =~ "count=500"
      assert q =~ "trading_sessions=REGULAR"
      Req.Test.json(conn, %{"result" => []})
    end)

    assert {:ok, _} =
             ExWebull.MarketData.bars(client, "AAPL", "US_STOCK", "m1",
               count: 500,
               trading_sessions: "REGULAR"
             )
  end

  test "batch_bars/5 posts JSON body", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert %{
               "symbols" => ["AAPL", "TSLA"],
               "category" => "US_STOCK",
               "timespan" => "m1",
               "count" => 100
             } = Jason.decode!(body)

      Req.Test.json(conn, %{"result" => []})
    end)

    assert {:ok, _} =
             ExWebull.MarketData.batch_bars(client, ["AAPL", "TSLA"], "US_STOCK", "m1",
               count: 100
             )
  end

  test "eod_bars/4 forwards count and date, drops nils", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/market-data/eod-bars"
      q = conn.query_string
      assert q =~ "symbol=AAPL"
      assert q =~ "category=US_STOCK"
      assert q =~ "count=30"
      assert q =~ "date=2026-01-15"
      Req.Test.json(conn, %{"result" => []})
    end)

    assert {:ok, _} =
             ExWebull.MarketData.eod_bars(client, "AAPL", "US_STOCK",
               count: 30,
               date: "2026-01-15"
             )
  end
end
