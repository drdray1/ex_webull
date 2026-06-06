defmodule ExWebull.Market.TokenTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.Token
  alias ExWebull.Proto.Quote.{SubscribeRequest, TokenResponse}

  test "get/1 requests the streaming token endpoint" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/streaming/token"
      assert req_mod == SubscribeRequest
      assert resp_mod == TokenResponse
      assert %SubscribeRequest{} = req
      {:ok, %TokenResponse{token: "TKN-1"}}
    end)

    assert {:ok, %TokenResponse{token: "TKN-1"}} = Token.get(:grpc)
  end
end
