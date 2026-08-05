defmodule ExWebull.News do
  @moduledoc """
  LLM-generated news summaries — `/openapi/news/summary`.

  Rate limited to 10 calls per minute per user.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Summarises news for a set of symbols (`POST /openapi/news/summary`).

  `category_symbols` is a list of `%{category: ..., symbols: [...]}`
  maps.

      ExWebull.News.summary(md, [%{category: "US_STOCK", symbols: ["AAPL"]}])

  ## Options

    - `:lang` — currently only `"en"`.
  """
  @spec summary(client(), map() | [map()], keyword()) :: response()
  def summary(client, category_symbols, opts \\ []) do
    Request.post(client, "/openapi/news/summary", %{
      category_symbols: List.wrap(category_symbols),
      lang: opts[:lang]
    })
  end
end
