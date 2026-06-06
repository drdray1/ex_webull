defmodule ExWebull.MarketData do
  @moduledoc """
  Webull Market Data HTTP endpoints — snapshots and historical bars.

  For live streaming quotes and tick-by-tick data, see
  `ExWebull.Mqtt.Connection` (market push) and `ExWebull.Market.*`
  (gRPC request/response).
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Fetches snapshots for given symbols (`GET /market-data/snapshot`)."
  @spec snapshot(client(), String.t(), String.t()) :: response()
  def snapshot(client, symbols, category) do
    client
    |> Req.get(url: "/market-data/snapshot", params: [symbols: symbols, category: category])
    |> Client.handle_response()
  end

  @doc """
  Fetches historical bars (`GET /market-data/bars`).

  ## Params
    - `symbol` — e.g. `"AAPL"`
    - `category` — e.g. `"US_STOCK"`
    - `timespan` — e.g. `"m1"`, `"d1"`

  ## Options
    - `:count` — max 1000 (default 200)
    - `:real_time_required` — `"true"` to include real-time data
    - `:trading_sessions` — e.g. `"PRE_MARKET"`, `"REGULAR"`, `"POST_MARKET"`
  """
  @spec bars(client(), String.t(), String.t(), String.t(), keyword()) :: response()
  def bars(client, symbol, category, timespan, opts \\ []) do
    params =
      [symbol: symbol, category: category, timespan: timespan]
      |> Keyword.merge(
        opts
        |> Keyword.take([:count, :real_time_required, :trading_sessions])
        |> drop_nil()
      )

    client |> Req.get(url: "/market-data/bars", params: params) |> Client.handle_response()
  end

  @doc "Fetches batch historical bars (`POST /market-data/batch-bars`)."
  @spec batch_bars(client(), [String.t()], String.t(), String.t(), keyword()) :: response()
  def batch_bars(client, symbols, category, timespan, opts \\ []) do
    body =
      %{symbols: symbols, category: category, timespan: timespan}
      |> maybe_put(:count, Keyword.get(opts, :count))
      |> maybe_put(:real_time_required, Keyword.get(opts, :real_time_required))
      |> maybe_put(:trading_sessions, Keyword.get(opts, :trading_sessions))

    client
    |> Req.post(url: "/market-data/batch-bars", json: body)
    |> Client.handle_response()
  end

  @doc "Fetches end-of-day bars (`GET /market-data/eod-bars`)."
  @spec eod_bars(client(), String.t(), String.t(), keyword()) :: response()
  def eod_bars(client, symbol, category, opts \\ []) do
    params =
      [symbol: symbol, category: category]
      |> Keyword.merge(opts |> Keyword.take([:count, :date]) |> drop_nil())

    client |> Req.get(url: "/market-data/eod-bars", params: params) |> Client.handle_response()
  end

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)

  defp drop_nil(kw), do: Enum.reject(kw, fn {_k, v} -> is_nil(v) end)
end
