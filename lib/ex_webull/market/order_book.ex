defmodule ExWebull.Market.OrderBook do
  @moduledoc "Order book (quote) over gRPC (`/market-data/quotes`)."

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{QuoteRequest, QuoteResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc "Fetches the current order book for a single symbol."
  @spec get(Client.t(), String.t(), String.t()) :: response()
  def get(client, symbol, category) do
    req = %QuoteRequest{symbol: symbol, category: category}
    Client.request(client, "/market-data/quotes", req, QuoteRequest, QuoteResponse)
  end
end
