defmodule ExWebull.MarketData.Futures do
  @moduledoc """
  Futures market data — `/openapi/market-data/futures/*`.

  Symbols are contract symbols, e.g. `"SILZ5"`, `"6BM6"`. Look them up
  with `ExWebull.Instruments.futures/2`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Real-time snapshots (`GET /openapi/market-data/futures/snapshot`).

  `symbols` is a symbol or list of up to 20.
  """
  @spec snapshot(client(), String.t() | [String.t()], keyword()) :: response()
  def snapshot(client, symbols, opts \\ []) do
    Request.get(client, "/openapi/market-data/futures/snapshot",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_FUTURES"
    )
  end

  @doc """
  Level-2 order book (`GET /openapi/market-data/futures/depth`).

  `depth` is the number of levels per side, 1–10. Level-1 data comes
  from `snapshot/3`.
  """
  @spec depth(client(), String.t(), pos_integer(), keyword()) :: response()
  def depth(client, symbol, depth, opts \\ []) do
    Request.get(client, "/openapi/market-data/futures/depth",
      symbol: symbol,
      category: opts[:category] || "US_FUTURES",
      depth: depth
    )
  end

  @doc """
  Tick-by-tick trades (`GET /openapi/market-data/futures/tick`).

  Sorted newest first. `count` is capped at 1200.
  """
  @spec tick(client(), String.t(), pos_integer(), keyword()) :: response()
  def tick(client, symbol, count, opts \\ []) do
    Request.get(client, "/openapi/market-data/futures/tick",
      symbol: symbol,
      category: opts[:category] || "US_FUTURES",
      count: count
    )
  end

  @doc """
  Historical bars (`GET /openapi/market-data/futures/bars`).

  `symbols` is a symbol or list of up to 20. `count` is capped at 1200.
  """
  @spec bars(client(), String.t() | [String.t()], String.t(), pos_integer(), keyword()) ::
          response()
  def bars(client, symbols, timespan, count, opts \\ []) do
    Request.get(client, "/openapi/market-data/futures/bars",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_FUTURES",
      timespan: timespan,
      count: count
    )
  end

  @doc """
  Order-flow footprint (`GET /openapi/market-data/futures/footprint`).

  `timespan` is one of `"S5"`, `"S15"`, `"M1"`, `"M5"`, `"M30"`.

  ## Options

    - `:count` — default 200, max 1200.
    - `:real_time_required` — include the in-progress bar.
    - `:trading_sessions` — `"PRE"`, `"RTH"`, `"ATH"` (no `"OVN"`).
  """
  @spec footprint(client(), String.t() | [String.t()], String.t(), keyword()) :: response()
  def footprint(client, symbols, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/futures/footprint",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_FUTURES",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required],
      trading_sessions: opts[:trading_sessions] && Request.symbols(opts[:trading_sessions])
    )
  end
end
