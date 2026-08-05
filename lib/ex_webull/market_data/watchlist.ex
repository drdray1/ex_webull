defmodule ExWebull.MarketData.Watchlist do
  @moduledoc """
  Watchlists — `/openapi/market-data/watchlist/*`.

  Up to 20 watchlists and 1000 instruments in total, shared with the
  retail Webull app. Event contracts, futures, and options are not
  supported.

  Instruments are maps of `%{symbol: ..., category: ...}`, optionally
  with `sort_order`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Lists all watchlists (`GET /openapi/market-data/watchlist/list`)."
  @spec list(client()) :: response()
  def list(client), do: Request.get(client, "/openapi/market-data/watchlist/list")

  @doc """
  Creates a watchlist (`POST /openapi/market-data/watchlist/create`).

  ## Options

    - `:sort` — sort order number.
  """
  @spec create(client(), String.t(), keyword()) :: response()
  def create(client, name, opts \\ []) do
    Request.post(client, "/openapi/market-data/watchlist/create", %{
      name: name,
      sort: opts[:sort]
    })
  end

  @doc """
  Renames or reorders a watchlist
  (`POST /openapi/market-data/watchlist/update`).

  Only the fields you pass are changed.

  ## Options

    - `:name` — new name.
    - `:sort` — new sort order number.
  """
  @spec update(client(), String.t(), keyword()) :: response()
  def update(client, watchlist_id, opts \\ []) do
    Request.post(client, "/openapi/market-data/watchlist/update", %{
      watchlist_id: watchlist_id,
      name: opts[:name],
      sort: opts[:sort]
    })
  end

  @doc """
  Deletes a watchlist and its contents
  (`POST /openapi/market-data/watchlist/delete`). Irreversible.
  """
  @spec delete(client(), String.t()) :: response()
  def delete(client, watchlist_id) do
    Request.post(client, "/openapi/market-data/watchlist/delete", %{
      watchlist_id: watchlist_id
    })
  end

  @doc """
  Lists a watchlist's instruments
  (`GET /openapi/market-data/watchlist/instruments/list`).
  """
  @spec instruments(client(), String.t()) :: response()
  def instruments(client, watchlist_id) do
    Request.get(client, "/openapi/market-data/watchlist/instruments/list",
      watchlist_id: watchlist_id
    )
  end

  @doc """
  Adds instruments
  (`POST /openapi/market-data/watchlist/instruments/add`).
  """
  @spec add_instruments(client(), String.t(), map() | [map()]) :: response()
  def add_instruments(client, watchlist_id, instruments) do
    Request.post(client, "/openapi/market-data/watchlist/instruments/add", %{
      watchlist_id: watchlist_id,
      instruments: List.wrap(instruments)
    })
  end

  @doc """
  Removes instruments
  (`POST /openapi/market-data/watchlist/instruments/remove`).
  """
  @spec remove_instruments(client(), String.t(), map() | [map()]) :: response()
  def remove_instruments(client, watchlist_id, instruments) do
    Request.post(client, "/openapi/market-data/watchlist/instruments/remove", %{
      watchlist_id: watchlist_id,
      instruments: List.wrap(instruments)
    })
  end

  @doc """
  Reorders instruments
  (`POST /openapi/market-data/watchlist/instruments/update`).
  """
  @spec update_instruments(client(), String.t(), map() | [map()]) :: response()
  def update_instruments(client, watchlist_id, instruments) do
    Request.post(client, "/openapi/market-data/watchlist/instruments/update", %{
      watchlist_id: watchlist_id,
      instruments: List.wrap(instruments)
    })
  end
end
