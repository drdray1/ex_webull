defmodule ExWebull.Fundamentals.Financial do
  @moduledoc """
  Financial statements and ratios — `/openapi/fundamentals/financial/*`.

  The statement functions share two options: `:type`, either `"ANNUAL"`
  or `"QUARTERLY"`, and `:count`, the number of periods (default 5,
  max 20).
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Income statement (`GET /openapi/fundamentals/financial/income`)."
  @spec income(client(), String.t(), keyword()) :: response()
  def income(client, symbol, opts \\ []),
    do: statement(client, "/openapi/fundamentals/financial/income", symbol, opts)

  @doc "Balance sheet (`GET /openapi/fundamentals/financial/balance-sheet`)."
  @spec balance_sheet(client(), String.t(), keyword()) :: response()
  def balance_sheet(client, symbol, opts \\ []),
    do: statement(client, "/openapi/fundamentals/financial/balance-sheet", symbol, opts)

  @doc "Cash flow statement (`GET /openapi/fundamentals/financial/cash-flow`)."
  @spec cash_flow(client(), String.t(), keyword()) :: response()
  def cash_flow(client, symbol, opts \\ []),
    do: statement(client, "/openapi/fundamentals/financial/cash-flow", symbol, opts)

  @doc """
  Key ratios (`GET /openapi/fundamentals/financial/indicators`).

  ROA, ROE, EPS, net margin, debt ratio, and similar.
  """
  @spec indicators(client(), String.t(), keyword()) :: response()
  def indicators(client, symbol, opts \\ []),
    do: statement(client, "/openapi/fundamentals/financial/indicators", symbol, opts)

  @doc """
  Earnings alert (`GET /openapi/fundamentals/financial/alert`).

  Next report estimates compared against the same period last year.
  """
  @spec alert(client(), String.t(), keyword()) :: response()
  def alert(client, symbol, opts \\ []) do
    Request.get(client, "/openapi/fundamentals/financial/alert",
      symbol: symbol,
      category: opts[:category] || "US_STOCK"
    )
  end

  defp statement(client, path, symbol, opts) do
    Request.get(client, path,
      symbol: symbol,
      category: opts[:category] || "US_STOCK",
      type: opts[:type],
      count: opts[:count]
    )
  end
end
