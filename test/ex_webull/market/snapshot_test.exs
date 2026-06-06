defmodule ExWebull.Market.SnapshotTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExWebull.Market.Snapshot
  alias ExWebull.Proto.Quote.{SnapshotRequest, SnapshotResponse}

  test "get/3 builds a SnapshotRequest and decodes the response" do
    expect(ExWebull.Grpc.Client, :request, fn :grpc, path, req, req_mod, resp_mod ->
      assert path == "/market-data/snapshot"
      assert req_mod == SnapshotRequest
      assert resp_mod == SnapshotResponse
      assert %SnapshotRequest{symbols: "AAPL,TSLA", category: "US_STOCK"} = req
      {:ok, %SnapshotResponse{}}
    end)

    assert {:ok, %SnapshotResponse{}} = Snapshot.get(:grpc, "AAPL,TSLA", "US_STOCK")
  end

  test "get/3 propagates errors" do
    expect(ExWebull.Grpc.Client, :request, fn _c, _p, _r, _rm, _resp ->
      {:error, {:api_error, 500, "boom"}}
    end)

    assert {:error, {:api_error, 500, "boom"}} = Snapshot.get(:grpc, "AAPL", "US_STOCK")
  end
end
