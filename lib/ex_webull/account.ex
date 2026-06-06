defmodule ExWebull.Account do
  @moduledoc """
  Webull v2 Account endpoints.

  All functions take a client created by `ExWebull.Client.new/3`.
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Lists the subscribed brokerage accounts (`GET /openapi/account/list`)."
  @spec list(client()) :: response()
  def list(client) do
    client
    |> Req.get(url: "/openapi/account/list")
    |> Client.handle_response()
  end

  @doc "Gets balance for the given account (`GET /openapi/account/balance`)."
  @spec balance(client(), String.t()) :: response()
  def balance(client, account_id) do
    client
    |> Req.get(url: "/openapi/account/balance", params: [account_id: account_id])
    |> Client.handle_response()
  end

  @doc "Gets positions for the given account (`GET /openapi/account/positions`)."
  @spec positions(client(), String.t()) :: response()
  def positions(client, account_id) do
    client
    |> Req.get(url: "/openapi/account/positions", params: [account_id: account_id])
    |> Client.handle_response()
  end

  @doc """
  Gets paginated position details (`GET /openapi/account/position/details`).

  ## Options

    - `:instrument_id` — filter for a specific instrument.
    - `:size` — page size (default 20).
    - `:last_instrument_id` — pagination cursor.
  """
  @spec position_details(client(), String.t(), keyword()) :: response()
  def position_details(client, account_id, opts \\ []) do
    params =
      [account_id: account_id]
      |> Keyword.merge(
        opts
        |> Keyword.take([:instrument_id, :size, :last_instrument_id])
        |> drop_nil()
      )

    client
    |> Req.get(url: "/openapi/account/position/details", params: params)
    |> Client.handle_response()
  end

  @doc "Fetches the account profile (`GET /account/profile`, legacy v1)."
  @spec profile(client()) :: response()
  def profile(client) do
    client |> Req.get(url: "/account/profile") |> Client.handle_response()
  end

  defp drop_nil(kw), do: Enum.reject(kw, fn {_k, v} -> is_nil(v) end)
end
