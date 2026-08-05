defmodule ExWebull.MarketData.ScreenerTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.MarketData.Screener

  setup do
    stub = :"screener_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp query(conn), do: URI.decode_query(conn.query_string)

  test "gainers_losers/2 applies documented defaults", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/gainers-losers"
      q = query(conn)
      assert q["category"] == "US_STOCK"
      assert q["rank_type"] == "DAY_1"
      assert q["sort_by"] == "CHANGE_RATIO"
      refute Map.has_key?(q, "direction")
      Req.Test.json(conn, [])
    end)

    Screener.gainers_losers(client)
  end

  test "gainers_losers/2 flips direction for losers", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      q = query(conn)
      assert q["direction"] == "ASC"
      assert q["rank_type"] == "WEEK_52"
      Req.Test.json(conn, [])
    end)

    Screener.gainers_losers(client, direction: "ASC", rank_type: "WEEK_52")
  end

  test "top_active/2, high_dividend/2 and week_52_high_low/2 hit their paths", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/top-active"
      assert query(conn)["rank_type"] == "TURNOVER"
      Req.Test.json(conn, [])
    end)

    Screener.top_active(client, rank_type: "TURNOVER")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/high-dividend"
      Req.Test.json(conn, [])
    end)

    Screener.high_dividend(client)

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/52whl"
      assert query(conn)["rank_type"] == "NEW_HIGH"
      Req.Test.json(conn, [])
    end)

    Screener.week_52_high_low(client, rank_type: "NEW_HIGH")
  end

  test "market_sectors/2 and market_sector_detail/3", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/market-sectors"
      assert query(conn)["agg_type"] == "VOLUME"
      Req.Test.json(conn, [])
    end)

    Screener.market_sectors(client, agg_type: "VOLUME")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/screener/market-sectors-detail"
      q = query(conn)
      assert q["sector_id"] == "SEC-1"
      assert q["period"] == "MO3"
      Req.Test.json(conn, [])
    end)

    Screener.market_sector_detail(client, "SEC-1", period: "MO3")
  end

  test "screeners default the category when opts are omitted", %{stub: stub, client: client} do
    calls = [
      {"/openapi/market-data/screener/top-active", fn -> Screener.top_active(client) end},
      {"/openapi/market-data/screener/52whl", fn -> Screener.week_52_high_low(client) end},
      {"/openapi/market-data/screener/market-sectors", fn -> Screener.market_sectors(client) end},
      {"/openapi/market-data/screener/market-sectors-detail",
       fn -> Screener.market_sector_detail(client, "SEC-1") end}
    ]

    for {path, call} <- calls do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        assert URI.decode_query(conn.query_string)["category"] == "US_STOCK"
        Req.Test.json(conn, [])
      end)

      assert {:ok, _} = call.()
    end
  end
end
