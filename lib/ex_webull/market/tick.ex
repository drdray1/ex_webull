defmodule ExWebull.Market.Tick do
  @moduledoc "Tick-by-tick trades over gRPC (`/market-data/tick`)."

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{TickRequest, TickResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc "Fetches the most recent `count` ticks (default 30)."
  @spec get(Client.t(), String.t(), String.t(), String.t()) :: response()
  def get(client, symbol, category, count \\ "30") do
    req = %TickRequest{symbol: symbol, category: category, count: count}
    Client.request(client, "/market-data/tick", req, TickRequest, TickResponse)
  end
end
