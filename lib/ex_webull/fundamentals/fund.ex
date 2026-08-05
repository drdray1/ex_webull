defmodule ExWebull.Fundamentals.Fund do
  @moduledoc """
  Mutual fund and ETF data — `/openapi/fundamentals/fund/*`.

  `:category` is `"US_STOCK"` throughout — funds are addressed by their
  ticker.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Fund brief (`GET /openapi/fundamentals/fund/brief`).

  Investment objective and managers.
  """
  @spec brief(client(), String.t(), keyword()) :: response()
  def brief(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/brief", symbol, opts)

  @doc """
  Performance (`GET /openapi/fundamentals/fund/performance`).

  Returns over multiple horizons.
  """
  @spec performance(client(), String.t(), keyword()) :: response()
  def performance(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/performance", symbol, opts)

  @doc "Top 10 holdings (`GET /openapi/fundamentals/fund/holdings`)."
  @spec holdings(client(), String.t(), keyword()) :: response()
  def holdings(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/holdings", symbol, opts)

  @doc "Asset allocation (`GET /openapi/fundamentals/fund/allocation`)."
  @spec allocation(client(), String.t(), keyword()) :: response()
  def allocation(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/allocation", symbol, opts)

  @doc "Rating history (`GET /openapi/fundamentals/fund/rating`)."
  @spec rating(client(), String.t(), keyword()) :: response()
  def rating(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/rating", symbol, opts)

  @doc "Split history (`GET /openapi/fundamentals/fund/splits`)."
  @spec splits(client(), String.t(), keyword()) :: response()
  def splits(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/splits", symbol, opts)

  @doc "Documents and files (`GET /openapi/fundamentals/fund/files`)."
  @spec files(client(), String.t(), keyword()) :: response()
  def files(client, symbol, opts \\ []),
    do: simple(client, "/openapi/fundamentals/fund/files", symbol, opts)

  @doc """
  Net asset value history (`GET /openapi/fundamentals/fund/net-value`).

  ## Options

    - `:last_date` — cursor for paging back through history.
    - `:count` — default 5, max 20.
  """
  @spec net_value(client(), String.t(), keyword()) :: response()
  def net_value(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/fund/net-value",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      last_date: opts[:last_date],
      count: opts[:count]
    )
  end

  @doc """
  Dividend history (`GET /openapi/fundamentals/fund/dividends`).

  ## Options

    - `:page_index` — 1-based, default 1.
    - `:page_size` — default 10, max 20.
  """
  @spec dividends(client(), String.t(), keyword()) :: response()
  def dividends(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/fund/dividends",
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      page_index: opts[:page_index],
      page_size: opts[:page_size]
    )
  end

  defp simple(client, path, symbol, opts) do
    Request.get(client, path, symbol: symbol, category: opts[:category] || "US_STOCK")
  end
end
