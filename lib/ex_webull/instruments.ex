defmodule ExWebull.Instruments do
  @moduledoc """
  Static instrument reference data — `/openapi/instrument/*`.

  Contract and security definitions for every asset class, plus company
  profiles and analyst coverage. Live prices live under
  `ExWebull.MarketData.*`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  # ---- Stocks -------------------------------------------------------------

  @doc """
  Stock and ETF instruments (`GET /openapi/instrument/stock/list`).

  ## Options

    - `:symbols` — up to 100 symbols, comma-separated or a list.
    - `:category` — default `"US_STOCK"`.
    - `:status` — `"OC"` (tradable), `"CO"` (liquidate only), `"NT"`
      (non-tradable).
    - `:page_size` — default 1000.
    - `:last_instrument_id` — cursor from the previous page.
  """
  @spec stocks(client(), keyword()) :: response()
  def stocks(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/stock/list",
      category: opts[:category] || "US_STOCK",
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      status: opts[:status],
      page_size: opts[:page_size],
      last_instrument_id: opts[:last_instrument_id]
    )
  end

  # ---- Options ------------------------------------------------------------

  @doc """
  Option contracts (`GET /openapi/instrument/option/contracts`).

  Static contract data — one entry per OCC symbol, with strike,
  expiration, multiplier, exercise style, and optionally deliverables.

  ## Options

    - `:category` — default `"US_OPTION"`.
    - `:underlying_symbols` — comma-separated underlyings, or a list.
    - `:option_symbol` — a single OCC symbol, e.g. `"AAPL260619C00180000"`.
    - `:status` — `"LISTING"` (default) or `"DELISTING"`.
    - `:start_date` — exact expiration date, `yyyy-MM-dd`.
    - `:end_date` — expiration lower bound (inclusive), `yyyy-MM-dd`.
    - `:root_symbol` — series symbol, e.g. `"SPXW"`.
    - `:option_type` — `"CALL"` or `"PUT"`.
    - `:style` — `"AMERICAN"` or `"EUROPEAN"`.
    - `:strike_price_gte` / `:strike_price_lte` — strike bounds.
    - `:ppind` — Penny Program indicator.
    - `:show_deliverables` — `"TRUE"` to include the deliverables array.
    - `:page_size` — default 100, max 1000.
    - `:last_instrument_id` — cursor from the previous page.
  """
  @spec options(client(), keyword()) :: response()
  def options(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/option/contracts",
      category: opts[:category] || "US_OPTION",
      underlying_symbols: opts[:underlying_symbols] && Request.symbols(opts[:underlying_symbols]),
      option_symbol: opts[:option_symbol],
      status: opts[:status],
      start_date: opts[:start_date],
      end_date: opts[:end_date],
      root_symbol: opts[:root_symbol],
      option_type: opts[:option_type],
      style: opts[:style],
      strike_price_gte: opts[:strike_price_gte],
      strike_price_lte: opts[:strike_price_lte],
      ppind: opts[:ppind],
      show_deliverables: opts[:show_deliverables],
      page_size: opts[:page_size],
      last_instrument_id: opts[:last_instrument_id]
    )
  end

  # ---- Futures ------------------------------------------------------------

  @doc """
  Futures contracts (`GET /openapi/instrument/futures/list`).

  Either `:symbols` or `:code` must be given.

  ## Options

    - `:category` — default `"US_FUTURES"`.
    - `:symbols` — up to 100 symbols, e.g. `"SILZ5,6BM6"`.
    - `:code` — futures product codes.
    - `:status` — `"OC"` (default), `"CO"`, or `"NT"`.
  """
  @spec futures(client(), keyword()) :: response()
  def futures(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/futures/list",
      category: opts[:category] || "US_FUTURES",
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      code: opts[:code],
      status: opts[:status]
    )
  end

  @doc """
  Futures underlying products (`GET /openapi/instrument/futures/products`).

  ## Options

    - `:category` — default `"US_FUTURES"`.
    - `:product_class_id` — narrow to one classification group.
  """
  @spec futures_products(client(), keyword()) :: response()
  def futures_products(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/futures/products",
      category: opts[:category] || "US_FUTURES",
      product_class_id: opts[:product_class_id]
    )
  end

  @doc "Futures product classes (`GET /openapi/instrument/futures/product-classes`)."
  @spec futures_product_classes(client(), keyword()) :: response()
  def futures_product_classes(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/futures/product-classes",
      category: opts[:category] || "US_FUTURES"
    )
  end

  # ---- Crypto -------------------------------------------------------------

  @doc """
  Crypto trading pairs (`GET /openapi/instrument/crypto/list`).

  ## Options

    - `:category` — default `"US_CRYPTO"`.
    - `:symbols` — up to 100 symbols.
    - `:status` — `"OC"`, `"CO"`, or `"NT"`.
    - `:page_size` — default 1000.
    - `:last_instrument_id` — cursor from the previous page.
  """
  @spec crypto(client(), keyword()) :: response()
  def crypto(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/crypto/list",
      category: opts[:category] || "US_CRYPTO",
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      status: opts[:status],
      page_size: opts[:page_size],
      last_instrument_id: opts[:last_instrument_id]
    )
  end

  # ---- Event contracts ----------------------------------------------------

  @doc "Event contract categories (`GET /openapi/instrument/event/categories`)."
  @spec event_categories(client()) :: response()
  def event_categories(client), do: Request.get(client, "/openapi/instrument/event/categories")

  @doc """
  Event contract series (`GET /openapi/instrument/event/series/list`).

  A series is a template for recurring events, e.g. "Monthly Jobs Report".

  ## Options

    - `:category` — `"ECONOMICS"`, `"FINANCIALS"`, `"POLITICS"`,
      `"ENTERTAINMENT"`, `"SCIENCE_TECHNOLOGY"`, `"CLIMATE_WEATHER"`,
      `"TRANSPORTATION"`, `"CRYPTO"`, or `"SPORTS"`.
    - `:symbols` — up to 100 series symbols.
    - `:page_size` — default 500.
    - `:last_series_id` — cursor from the previous page.
  """
  @spec event_series(client(), keyword()) :: response()
  def event_series(client, opts \\ []) do
    Request.get(client, "/openapi/instrument/event/series/list",
      category: opts[:category],
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      page_size: opts[:page_size],
      last_series_id: opts[:last_series_id]
    )
  end

  @doc """
  Events within a series (`GET /openapi/instrument/event/events`).

  ## Options

    - `:symbols` — up to 100 event symbols.
    - `:status` — `"ACTIVE"` or `"INACTIVE"`.
  """
  @spec event_events(client(), String.t(), keyword()) :: response()
  def event_events(client, series_symbol, opts \\ []) do
    Request.get(client, "/openapi/instrument/event/events",
      series_symbol: series_symbol,
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      status: opts[:status]
    )
  end

  @doc """
  Event contract markets (`GET /openapi/instrument/event/market/list`).

  ## Options

    - `:event_symbol` — narrow to a single event.
    - `:symbols` — up to 100 market symbols.
    - `:expiration_date_after` — filter to expirations after this date;
      defaults to today, inclusive.
    - `:page_size` — default 500.
    - `:last_instrument_id` — cursor from the previous page.
  """
  @spec event_markets(client(), String.t(), keyword()) :: response()
  def event_markets(client, series_symbol, opts \\ []) do
    Request.get(client, "/openapi/instrument/event/market/list",
      series_symbol: series_symbol,
      event_symbol: opts[:event_symbol],
      symbols: opts[:symbols] && Request.symbols(opts[:symbols]),
      expiration_date_after: opts[:expiration_date_after],
      page_size: opts[:page_size],
      last_instrument_id: opts[:last_instrument_id]
    )
  end

  # ---- Company and analyst coverage ---------------------------------------

  @doc """
  Company profile (`GET /openapi/instrument/company/profile`).

  Business description, industry, sector, CEO, and headquarters.
  """
  @spec company_profile(client(), String.t(), keyword()) :: response()
  def company_profile(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/instrument/company/profile",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  Analyst ratings (`GET /openapi/instrument/analyst/rating`).

  Counts of Strong Buy / Buy / Hold / Sell / Strong Sell ratings.
  """
  @spec analyst_rating(client(), String.t(), keyword()) :: response()
  def analyst_rating(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/instrument/analyst/rating",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  Analyst target prices (`GET /openapi/instrument/analyst/target-price`).

  High, low, mean, and median targets.
  """
  @spec analyst_target_price(client(), String.t(), keyword()) :: response()
  def analyst_target_price(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/instrument/analyst/target-price",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end
end
