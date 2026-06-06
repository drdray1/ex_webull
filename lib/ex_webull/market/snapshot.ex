defmodule ExWebull.Market.Snapshot do
  @moduledoc "Market snapshots over gRPC (`/market-data/snapshot`)."

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{SnapshotRequest, SnapshotResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc "Fetches snapshots for comma-separated symbols."
  @spec get(Client.t(), String.t(), String.t()) :: response()
  def get(client, symbols, category) do
    req = %SnapshotRequest{symbols: symbols, category: category}
    Client.request(client, "/market-data/snapshot", req, SnapshotRequest, SnapshotResponse)
  end
end
