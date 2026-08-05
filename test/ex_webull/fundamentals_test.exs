defmodule ExWebull.FundamentalsTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.Fundamentals.{Financial, Fund, Stock}

  setup do
    stub = :"fundamentals_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp query(conn), do: URI.decode_query(conn.query_string)

  defp expect_path(stub, path, extra \\ %{}) do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == path
      q = URI.decode_query(conn.query_string)
      assert q["symbol"] == "AAPL"
      assert q["category"] == "US_STOCK"
      for {k, v} <- extra, do: assert(q[k] == v)
      Req.Test.json(conn, %{})
    end)
  end

  test "stock fundamentals hit their paths", %{stub: stub, client: client} do
    expect_path(stub, "/openapi/fundamentals/stock/capital-flow", %{"count" => "3"})
    Stock.capital_flow(client, "AAPL", count: 3)

    expect_path(stub, "/openapi/fundamentals/stock/dividend-calendar")
    Stock.dividend_calendar(client, "AAPL")

    expect_path(stub, "/openapi/fundamentals/stock/earnings-calendar")
    Stock.earnings_calendar(client, "AAPL")

    expect_path(stub, "/openapi/fundamentals/stock/filings")
    Stock.filings(client, "AAPL")

    expect_path(stub, "/openapi/fundamentals/stock/forecast-eps")
    Stock.forecast_eps(client, "AAPL")

    expect_path(stub, "/openapi/fundamentals/stock/industry-comparison", %{
      "sort_by" => "PE_TTM"
    })

    Stock.industry_comparison(client, "AAPL", sort_by: "PE_TTM")
  end

  test "financial statements forward type and count", %{stub: stub, client: client} do
    for {fun, path} <- [
          {:income, "/openapi/fundamentals/financial/income"},
          {:balance_sheet, "/openapi/fundamentals/financial/balance-sheet"},
          {:cash_flow, "/openapi/fundamentals/financial/cash-flow"},
          {:indicators, "/openapi/fundamentals/financial/indicators"}
        ] do
      expect_path(stub, path, %{"type" => "ANNUAL", "count" => "10"})
      apply(Financial, fun, [client, "AAPL", [type: "ANNUAL", count: 10]])
    end
  end

  test "financial alert takes no statement options", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/fundamentals/financial/alert"
      refute Map.has_key?(query(conn), "type")
      Req.Test.json(conn, %{})
    end)

    Financial.alert(client, "AAPL")
  end

  test "fund endpoints hit their paths", %{stub: stub, client: client} do
    for {fun, path} <- [
          {:brief, "/openapi/fundamentals/fund/brief"},
          {:performance, "/openapi/fundamentals/fund/performance"},
          {:holdings, "/openapi/fundamentals/fund/holdings"},
          {:allocation, "/openapi/fundamentals/fund/allocation"},
          {:rating, "/openapi/fundamentals/fund/rating"},
          {:splits, "/openapi/fundamentals/fund/splits"},
          {:files, "/openapi/fundamentals/fund/files"}
        ] do
      expect_path(stub, path)
      apply(Fund, fun, [client, "AAPL"])
    end
  end

  test "fund net_value/3 and dividends/3 page", %{stub: stub, client: client} do
    expect_path(stub, "/openapi/fundamentals/fund/net-value", %{
      "last_date" => "2026-01-01",
      "count" => "20"
    })

    Fund.net_value(client, "AAPL", last_date: "2026-01-01", count: 20)

    expect_path(stub, "/openapi/fundamentals/fund/dividends", %{
      "page_index" => "2",
      "page_size" => "20"
    })

    Fund.dividends(client, "AAPL", page_index: 2, page_size: 20)
  end

  test "statements and fund pages apply defaults when opts are omitted", %{
    stub: stub,
    client: client
  } do
    calls = [
      {"/openapi/fundamentals/financial/income", fn -> Financial.income(client, "AAPL") end},
      {"/openapi/fundamentals/financial/balance-sheet",
       fn -> Financial.balance_sheet(client, "AAPL") end},
      {"/openapi/fundamentals/financial/cash-flow",
       fn -> Financial.cash_flow(client, "AAPL") end},
      {"/openapi/fundamentals/financial/indicators",
       fn -> Financial.indicators(client, "AAPL") end},
      {"/openapi/fundamentals/fund/net-value", fn -> Fund.net_value(client, "AAPL") end},
      {"/openapi/fundamentals/fund/dividends", fn -> Fund.dividends(client, "AAPL") end},
      {"/openapi/fundamentals/stock/capital-flow", fn -> Stock.capital_flow(client, "AAPL") end},
      {"/openapi/fundamentals/stock/industry-comparison",
       fn -> Stock.industry_comparison(client, "AAPL") end}
    ]

    for {path, call} <- calls do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        q = URI.decode_query(conn.query_string)
        assert q == %{"symbol" => "AAPL", "category" => "US_STOCK"}
        Req.Test.json(conn, %{})
      end)

      assert {:ok, _} = call.()
    end
  end
end
