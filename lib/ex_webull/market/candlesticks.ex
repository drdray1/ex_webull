defmodule ExWebull.Market.Candlesticks do
  @moduledoc """
  Historical OHLC bars over gRPC (`/market-data/bars` and
  `/market-data/batch-bars`).
  """

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{BarsRequest, BarsResponse, BatchBarsRequest, BatchBarsResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc """
  Fetches bars for a single symbol.

  ## Options

    - `:count` (default `"200"`)
    - `:real_time_required`
    - `:trading_sessions`
  """
  @spec get(Client.t(), String.t(), String.t(), String.t(), keyword()) :: response()
  def get(client, symbol, category, timespan, opts \\ []) do
    req = %BarsRequest{
      symbol: symbol,
      category: category,
      timespan: timespan,
      count: Keyword.get(opts, :count, "200"),
      real_time_required: Keyword.get(opts, :real_time_required, ""),
      trading_sessions: Keyword.get(opts, :trading_sessions, "")
    }

    Client.request(client, "/market-data/bars", req, BarsRequest, BarsResponse)
  end

  @doc "Fetches bars for multiple symbols via a batch request."
  @spec batch(Client.t(), [String.t()], String.t(), String.t(), keyword()) :: response()
  def batch(client, symbols, category, timespan, opts \\ []) do
    req = %BatchBarsRequest{
      symbols: symbols,
      category: category,
      timespan: timespan,
      count: Keyword.get(opts, :count, 200),
      real_time_required: Keyword.get(opts, :real_time_required, ""),
      trading_sessions: Keyword.get(opts, :trading_sessions, [])
    }

    Client.request(client, "/market-data/batch-bars", req, BatchBarsRequest, BatchBarsResponse)
  end
end
