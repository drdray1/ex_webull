defmodule ExWebull.Market.CandlesticksTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.Candlesticks
  alias ExWebull.Proto.Quote.{BarsRequest, BarsResponse, BatchBarsRequest, BatchBarsResponse}

  test "get/5 defaults count to \"200\" and builds a BarsRequest" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/bars"
      assert req_mod == BarsRequest
      assert resp_mod == BarsResponse

      assert %BarsRequest{
               symbol: "AAPL",
               category: "US_STOCK",
               timespan: "m1",
               count: "200"
             } = req

      {:ok, %BarsResponse{}}
    end)

    assert {:ok, %BarsResponse{}} = Candlesticks.get(:grpc, "AAPL", "US_STOCK", "m1")
  end

  test "get/5 forwards count and trading_sessions options" do
    expect(ExWebull.Grpc.Client, :request, fn _c, _p, req, _rm, _resp ->
      assert %BarsRequest{count: "500", trading_sessions: "REGULAR"} = req
      {:ok, %BarsResponse{}}
    end)

    assert {:ok, _} =
             Candlesticks.get(:grpc, "AAPL", "US_STOCK", "m1",
               count: "500",
               trading_sessions: "REGULAR"
             )
  end

  test "batch/5 builds a BatchBarsRequest with default count 200" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/batch-bars"
      assert req_mod == BatchBarsRequest
      assert resp_mod == BatchBarsResponse

      assert %BatchBarsRequest{
               symbols: ["AAPL", "TSLA"],
               category: "US_STOCK",
               timespan: "m1",
               count: 200
             } = req

      {:ok, %BatchBarsResponse{}}
    end)

    assert {:ok, %BatchBarsResponse{}} =
             Candlesticks.batch(:grpc, ["AAPL", "TSLA"], "US_STOCK", "m1")
  end
end
