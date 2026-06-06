defmodule ExWebull.Market.TickTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.Tick
  alias ExWebull.Proto.Quote.{TickRequest, TickResponse}

  test "get/4 defaults count to \"30\"" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/tick"
      assert req_mod == TickRequest
      assert resp_mod == TickResponse
      assert %TickRequest{symbol: "AAPL", category: "US_STOCK", count: "30"} = req
      {:ok, %TickResponse{}}
    end)

    assert {:ok, %TickResponse{}} = Tick.get(:grpc, "AAPL", "US_STOCK")
  end

  test "get/4 forwards an explicit count" do
    expect(ExWebull.Grpc.Client, :request, fn _c, _p, req, _rm, _resp ->
      assert %TickRequest{count: "100"} = req
      {:ok, %TickResponse{}}
    end)

    assert {:ok, _} = Tick.get(:grpc, "AAPL", "US_STOCK", "100")
  end
end
