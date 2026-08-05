defmodule ExWebull.MarketData.Option do
  @moduledoc """
  Option market data — `/openapi/market-data/option/*`.

  Symbols are OCC contract symbols, e.g. `"AAPL260619C00180000"`. Look
  them up with `ExWebull.Instruments.options/2`.

      md = ExWebull.Client.new_market_data("app_key", "app_secret")
      {:ok, quotes} = ExWebull.MarketData.Option.snapshot(md, "AAPL260619C00180000")
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Real-time snapshots (`GET /openapi/market-data/option/snapshot`).

  `symbols` is an OCC symbol or a list of up to 20. Includes greeks
  (delta, gamma, theta, vega, rho), implied volatility, open interest,
  and best bid/ask.
  """
  @spec snapshot(client(), String.t() | [String.t()], keyword()) :: response()
  def snapshot(client, symbols, opts \\ []) do
    Request.get(client, "/openapi/market-data/option/snapshot",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_OPTION"
    )
  end

  @doc """
  Tick-by-tick trades (`GET /openapi/market-data/option/tick`).

  Sorted newest first. `count` is capped at 1200.
  """
  @spec tick(client(), String.t(), pos_integer(), keyword()) :: response()
  def tick(client, symbol, count, opts \\ []) do
    Request.get(client, "/openapi/market-data/option/tick",
      symbol: symbol,
      category: opts[:category] || "US_OPTION",
      count: count
    )
  end

  @doc """
  Historical bars (`GET /openapi/market-data/option/bars`).

  `symbols` is an OCC symbol or a list of up to 20. `timespan` is one of
  `"M1"`, `"M5"`, `"M15"`, `"M30"`, `"M60"`, `"M120"`, `"M240"`, `"D"`,
  `"W"`, `"M"`, `"Y"`.

  ## Options

    - `:count` — max 1200.
    - `:real_time_required` — include the in-progress bar.
  """
  @spec bars(client(), String.t() | [String.t()], String.t(), keyword()) :: response()
  def bars(client, symbols, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/option/bars",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_OPTION",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required]
    )
  end
end
