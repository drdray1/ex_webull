defmodule ExWebull.Market.OrderBookTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.OrderBook
  alias ExWebull.Proto.Quote.{QuoteRequest, QuoteResponse}

  test "get/3 builds a QuoteRequest at the quotes path" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/quotes"
      assert req_mod == QuoteRequest
      assert resp_mod == QuoteResponse
      assert %QuoteRequest{symbol: "AAPL", category: "US_STOCK"} = req
      {:ok, %QuoteResponse{}}
    end)

    assert {:ok, %QuoteResponse{}} = OrderBook.get(:grpc, "AAPL", "US_STOCK")
  end
end
