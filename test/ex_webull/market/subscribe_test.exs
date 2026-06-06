defmodule ExWebull.Market.SubscribeTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.Subscribe
  alias ExWebull.Proto.Quote.{SubscribeRequest, SubscribeResponse}

  test "subscribe/5 builds a SubscribeRequest at the subscribe path" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/streaming/subscribe"
      assert req_mod == SubscribeRequest
      assert resp_mod == SubscribeResponse

      assert %SubscribeRequest{
               token: "TKN-1",
               symbols: ["AAPL"],
               category: "US_STOCK",
               sub_types: ["SNAPSHOT"]
             } = req

      {:ok, %SubscribeResponse{}}
    end)

    assert {:ok, %SubscribeResponse{}} =
             Subscribe.subscribe(:grpc, "TKN-1", ["AAPL"], "US_STOCK", ["SNAPSHOT"])
  end

  test "unsubscribe/6 defaults unsubscribe_all to empty string" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, _rm, _resp ->
      assert path == "/market-data/streaming/unsubscribe"
      assert %SubscribeRequest{unsubscribe_all: ""} = req
      {:ok, %SubscribeResponse{}}
    end)

    assert {:ok, _} =
             Subscribe.unsubscribe(:grpc, "TKN-1", ["AAPL"], "US_STOCK", ["SNAPSHOT"])
  end

  test "unsubscribe/6 forwards unsubscribe_all option" do
    expect(ExWebull.Grpc.Client, :request, fn _c, _p, req, _rm, _resp ->
      assert %SubscribeRequest{unsubscribe_all: "true"} = req
      {:ok, %SubscribeResponse{}}
    end)

    assert {:ok, _} =
             Subscribe.unsubscribe(:grpc, "TKN-1", [], "US_STOCK", [], unsubscribe_all: "true")
  end
end
