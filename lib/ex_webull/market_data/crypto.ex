defmodule ExWebull.MarketData.Crypto do
  @moduledoc """
  Crypto market data — `/openapi/market-data/crypto/*`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Real-time snapshots (`GET /openapi/market-data/crypto/snapshot`).

  `symbols` is a symbol or list of up to 20.
  """
  @spec snapshot(client(), String.t() | [String.t()], keyword()) :: response()
  def snapshot(client, symbols, opts \\ []) do
    Request.get(client, "/openapi/market-data/crypto/snapshot",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_CRYPTO"
    )
  end

  @doc """
  Historical bars (`GET /openapi/market-data/crypto/bars`).

  `symbols` is a symbol or list of up to 20. Daily and above are
  forward-adjusted; minute bars are unadjusted.

  ## Options

    - `:count` — default 200, range 1–1200.
    - `:real_time_required` — include the in-progress bar.
  """
  @spec bars(client(), String.t() | [String.t()], String.t(), keyword()) :: response()
  def bars(client, symbols, timespan, opts \\ []) do
    Request.get(client, "/openapi/market-data/crypto/bars",
      symbols: Request.symbols(symbols),
      category: opts[:category] || "US_CRYPTO",
      timespan: timespan,
      count: opts[:count],
      real_time_required: opts[:real_time_required]
    )
  end
end
