defmodule ExWebull.MarketData.Screener do
  @moduledoc """
  Ranked stock lists — `/openapi/market-data/screener/*`.

  `:sort_by` accepts `"CHANGE_RATIO"`, `"RELATIVE_VOLUME_10D"`,
  `"MARKET_VALUE"`, `"CLOSE"`, `"PRICE"`, `"PE_TTM"`, `"HIGH"`,
  `"LOW"`, `"AMPLITUDE"`, `"TURNOVER"`, `"VOLUME"`, and — where
  relevant — `"YIELD"` and `"DIVIDEND"`. `:direction` is `"ASC"` or
  `"DESC"`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Top gainers and losers
  (`GET /openapi/market-data/screener/gainers-losers`).

  Losers are the same list sorted the other way: pass
  `sort_by: "CHANGE_RATIO", direction: "ASC"`.

  ## Options

    - `:rank_type` — the change-calculation window: `"PRE_MARKET"`,
      `"AFTER_MARKET"`, `"MIN_3"`, `"MIN_5"`, `"DAY_1"` (default),
      `"DAY_5"`, `"MONTH_1"`, `"MONTH_3"`, `"WEEK_52"`.
    - `:sort_by` — default `"CHANGE_RATIO"`.
    - `:direction` — `"DESC"` (gainers, default) or `"ASC"` (losers).
    - `:page_index` — 1-based, default 1.
    - `:page_size` — default 20.
  """
  @spec gainers_losers(client(), keyword()) :: response()
  def gainers_losers(client, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/gainers-losers",
      category: opts[:category] || "US_STOCK",
      rank_type: opts[:rank_type] || "DAY_1",
      sort_by: opts[:sort_by] || "CHANGE_RATIO",
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  @doc """
  Most actively traded stocks
  (`GET /openapi/market-data/screener/top-active`).

  ## Options

    - `:rank_type` — the activity metric: `"VOLUME"` (default),
      `"RELATIVE_VOLUME_10D"`, `"TURNOVER"`, `"TURNOVER_RATE"`,
      `"AMPLITUDE"`.
    - `:sort_by` — secondary sort, default `"VOLUME"`.
    - `:direction`, `:page_index`, `:page_size`.
  """
  @spec top_active(client(), keyword()) :: response()
  def top_active(client, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/top-active",
      category: opts[:category] || "US_STOCK",
      rank_type: opts[:rank_type],
      sort_by: opts[:sort_by],
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  @doc """
  High dividend stocks (`GET /openapi/market-data/screener/high-dividend`).

  ## Options

    - `:sort_by` — default `"YIELD"`.
    - `:direction`, `:page_index`, `:page_size`.
  """
  @spec high_dividend(client(), keyword()) :: response()
  def high_dividend(client, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/high-dividend",
      category: opts[:category] || "US_STOCK",
      sort_by: opts[:sort_by],
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  @doc """
  52-week highs and lows (`GET /openapi/market-data/screener/52whl`).

  ## Options

    - `:rank_type` — `"NEW_HIGH"`, `"NEAR_HIGH"`, `"NEW_LOW"`,
      `"NEAR_LOW"`.
    - `:sort_by`, `:direction`, `:page_index`, `:page_size`.
  """
  @spec week_52_high_low(client(), keyword()) :: response()
  def week_52_high_low(client, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/52whl",
      category: opts[:category] || "US_STOCK",
      rank_type: opts[:rank_type],
      sort_by: opts[:sort_by],
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  @doc """
  Sector overview (`GET /openapi/market-data/screener/market-sectors`).

  ## Options

    - `:agg_type` — `"MARKET_VALUE"` (default) or `"VOLUME"`.
    - `:period` — `"D1"` (default), `"D5"`, `"MO1"`, `"MO3"`.
    - `:direction`, `:page_index`, `:page_size`.
  """
  @spec market_sectors(client(), keyword()) :: response()
  def market_sectors(client, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/market-sectors",
      category: opts[:category] || "US_STOCK",
      agg_type: opts[:agg_type],
      period: opts[:period],
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  @doc """
  Stocks within a sector
  (`GET /openapi/market-data/screener/market-sectors-detail`).

  ## Options

    - `:period` — `"D1"` (default), `"D5"`, `"MO1"`, `"MO3"`.
    - `:sort_by` — default `"CHANGE_RATIO"`.
    - `:direction`, `:page_index`, `:page_size`.
  """
  @spec market_sector_detail(client(), String.t(), keyword()) :: response()
  def market_sector_detail(client, sector_id, opts \\ []) do
    Request.get(client, "/openapi/market-data/screener/market-sectors-detail",
      sector_id: sector_id,
      category: opts[:category] || "US_STOCK",
      period: opts[:period],
      sort_by: opts[:sort_by],
      direction: opts[:direction],
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end
end
