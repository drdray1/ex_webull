defmodule ExWebull.Fundamentals.Stock do
  @moduledoc """
  Stock fundamentals — `/openapi/fundamentals/stock/*`.

  Single symbol per call; `:category` is `"US_STOCK"` throughout.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Capital flow distribution
  (`GET /openapi/fundamentals/stock/capital-flow`).

  ## Options

    - `:count` — trading days to return, 1–5, default 5. Sorted
      ascending by date.
  """
  @spec capital_flow(client(), String.t(), keyword()) :: response()
  def capital_flow(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/capital-flow",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      count: opts[:count]
    )
  end

  @doc """
  Dividend calendar (`GET /openapi/fundamentals/stock/dividend-calendar`).

  The most recent 6 records.
  """
  @spec dividend_calendar(client(), String.t(), keyword()) :: response()
  def dividend_calendar(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/dividend-calendar",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  Earnings calendar (`GET /openapi/fundamentals/stock/earnings-calendar`).

  EPS and revenue for the most recent 6 quarters.
  """
  @spec earnings_calendar(client(), String.t(), keyword()) :: response()
  def earnings_calendar(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/earnings-calendar",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  SEC filings (`GET /openapi/fundamentals/stock/filings`).

  The most recent 3 filings.
  """
  @spec filings(client(), String.t(), keyword()) :: response()
  def filings(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/filings",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  Forecast EPS (`GET /openapi/fundamentals/stock/forecast-eps`).

  The most recent 5 quarters.
  """
  @spec forecast_eps(client(), String.t(), keyword()) :: response()
  def forecast_eps(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/forecast-eps",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  @doc """
  Industry peer comparison
  (`GET /openapi/fundamentals/stock/industry-comparison`).

  Up to 20 symbols ranked by the given metric.

  ## Options

    - `:sort_by` — financial metric, default `"EPS_TTM"`.
  """
  @spec industry_comparison(client(), String.t(), keyword()) :: response()
  def industry_comparison(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/stock/industry-comparison",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      sort_by: opts[:sort_by]
    )
  end
end
