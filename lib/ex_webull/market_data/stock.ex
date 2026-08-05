defmodule ExWebull.MarketData.Stock do
  @moduledoc """
  Stock and ETF market data — `/openapi/market-data/stock/*`.

  Requires a market-data client:

      md = ExWebull.Client.new_market_data("app_key", "app_secret")
      {:ok, snap} = ExWebull.MarketData.Stock.snapshot(md, ["AAPL", "TSLA"])

  `:category` defaults to `"US_STOCK"` throughout; pass `"US_ETF"` for
  ETFs. Trading sessions are `"PRE"`, `"RTH"`, `"ATH"`, and `"OVN"`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Real-time snapshots (`GET /openapi/market-data/stock/snapshot`).

  `symbols` is a symbol or list of up to 100.

  ## Options

    - `:category` — default `"US_STOCK"`.
    - `:extend_hour_required` — include pre-market and after-hours data.
    - `:overnight_required` — include the overnight session.
  """
  @spec snapshot(client(), String.t() | [String.t()], keyword()) :: response()
  def snapshot(client, symbols, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/snapshot",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_STOCK",
      extend_hour_required: opts[:extend_hour_required],
      overnight_required: opts[:overnight_required]
    )
  end

  @doc """
  Bid/ask depth (`GET /openapi/market-data/stock/quotes`).

  ## Options

    - `:category` — default `"US_STOCK"`.
    - `:depth` — `"L1"` for one level, `"L2"` for ten (default).
    - `:overnight_required` — include overnight trading data.
  """
  @spec quotes(client(), String.t(), keyword()) :: response()
  def quotes(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/quotes",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      depth: opts[:depth],
      overnight_required: opts[:overnight_required]
    )
  end

  @doc """
  Tick-by-tick trades (`GET /openapi/market-data/stock/tick`).

  Sorted newest first.

  ## Options

    - `:category` — default `"US_STOCK"`.
    - `:count` — default 30, max 1000.
    - `:trading_sessions` — comma-separated sessions, or a list.
  """
  @spec tick(client(), String.t(), keyword()) :: response()
  def tick(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/tick",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      count: opts[:count],
      trading_sessions: opts[:trading_sessions] && Request.symbols(opts[:trading_sessions])
    )
  end

  @doc """
  Historical bars for one symbol (`GET /openapi/market-data/stock/bars`).

  `timespan` is one of `"M1"`, `"M5"`, `"M15"`, `"M30"`, `"M60"`,
  `"M120"`, `"M240"`, `"D"`, `"W"`, `"M"`, `"Y"`. Daily and above are
  forward-adjusted; minute bars are unadjusted.

  ## Options

    - `:category` — default `"US_STOCK"`.
    - `:count` — default 200, max 1200 (M1 supports 1650).
    - `:real_time_required` — include the in-progress bar.
    - `:trading_sessions` — comma-separated sessions, or a list.
    - `:start_time` / `:end_time` — epoch milliseconds.
  """
  @spec bars(client(), String.t(), String.t(), keyword()) :: response()
  def bars(client, symbol, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/bars",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required],
      trading_sessions: opts[:trading_sessions] && Request.symbols(opts[:trading_sessions]),
      start_time: opts[:start_time],
      end_time: opts[:end_time]
    )
  end

  @doc """
  Historical bars for up to 20 symbols
  (`POST /openapi/market-data/stock/batch-bars`).

  Same options as `bars/4`.
  """
  @spec batch_bars(client(), [String.t()], String.t(), keyword()) :: response()
  def batch_bars(client, symbols, timespan, opts \\ []) do
    Request.post(client, "/openapi/market-data/stock/batch-bars", %{
      symbols: List.wrap(symbols),
      category: opts[:category] || "US_STOCK",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required],
      trading_sessions: opts[:trading_sessions] && Request.symbols(opts[:trading_sessions]),
      start_time: opts[:start_time],
      end_time: opts[:end_time]
    })
  end

  @doc """
  Order-flow footprint (`GET /openapi/market-data/stock/footprint`).

  `timespan` is one of `"S5"`, `"S15"`, `"M1"`, `"M5"`, `"M30"`.

  ## Options

    - `:category` — default `"US_STOCK"`.
    - `:count` — default 200, max 1200.
    - `:real_time_required` — include the in-progress bar.
    - `:trading_sessions` — `"PRE"`, `"RTH"`, `"ATH"` (no `"OVN"`).
  """
  @spec footprint(client(), String.t() | [String.t()], String.t(), keyword()) :: response()
  def footprint(client, symbols, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/footprint",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_STOCK",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required],
      trading_sessions: opts[:trading_sessions] && Request.symbols(opts[:trading_sessions])
    )
  end

  @doc """
  NOII snapshot (`GET /openapi/market-data/stock/noii/snapshot`).

  Net Order Imbalance Indicator, published by NASDAQ during the opening
  and closing auctions. `imbalance_action_type` is `"PRE_OPEN"` or
  `"PRE_CLOSE"`.
  """
  @spec noii_snapshot(client(), String.t(), String.t(), keyword()) :: response()
  def noii_snapshot(client, symbol, imbalance_action_type, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/noii/snapshot",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      imbalance_action_type: imbalance_action_type
    )
  end

  @doc """
  NOII bars (`GET /openapi/market-data/stock/noii/bars`).

  `imbalance_action_type` is `"PRE_OPEN"` or `"PRE_CLOSE"`.
  """
  @spec noii_bars(client(), String.t(), String.t(), keyword()) :: response()
  def noii_bars(client, symbol, imbalance_action_type, opts \\ []) do
    Request.get(client, "/openapi/market-data/stock/noii/bars",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      imbalance_action_type: imbalance_action_type
    )
  end
end
