defmodule ExWebull.MarketData.Event do
  @moduledoc """
  Event contract market data — `/openapi/market-data/event/*`.

  Event contracts are binary markets. Discover symbols with
  `ExWebull.Instruments.event_markets/3`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Real-time snapshots (`GET /openapi/market-data/event/snapshot`).

  `symbols` is a symbol or list of up to 100.
  """
  @spec snapshot(client(), String.t() | [String.t()], keyword()) :: response()
  def snapshot(client, symbols, opts \\ []) do
    Request.get(client, "/openapi/market-data/event/snapshot",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_EVENT"
    )
  end

  @doc """
  Order book (`GET /openapi/market-data/event/depth`).

  Returns yes-bids and no-bids only — in a binary market a bid for yes
  at price X is equivalent to an ask for no at 1 - X, so asks are
  redundant.

  ## Options

    - `:depth` — levels per side, default 10.
  """
  @spec depth(client(), String.t(), keyword()) :: response()
  def depth(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/market-data/event/depth",
      symbol: symbol,
      category: opts[:category] || "US_EVENT",
      depth: opts[:depth]
    )
  end

  @doc """
  Tick-by-tick trades (`GET /openapi/market-data/event/tick`).

  Sorted newest first.

  ## Options

    - `:count` — default 30, max 1200.
  """
  @spec tick(client(), String.t(), keyword()) :: response()
  def tick(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/market-data/event/tick",
      symbol: symbol,
      category: opts[:category] || "US_EVENT",
      count: opts[:count]
    )
  end

  @doc """
  Historical bars (`GET /openapi/market-data/event/bars`).

  `symbols` is a symbol or list of up to 100. `timespan` is one of
  `"M1"`, `"M5"`, `"M15"`, `"M30"`, `"M60"`, `"M120"`, `"M240"`, `"D"`.

  ## Options

    - `:count` — default 200, max 1200.
    - `:real_time_required` — include the in-progress bar.
  """
  @spec bars(client(), String.t() | [String.t()], String.t(), keyword()) :: response()
  def bars(client, symbols, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/event/bars",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_EVENT",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required]
    )
  end
end
