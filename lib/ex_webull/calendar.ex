defmodule ExWebull.Calendar do
  @moduledoc """
  Webull Trading Calendar endpoint (`GET /trade/calendar`).
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Fetches the trading calendar.

  ## Options

  Forwards any key-value pairs as query params (e.g. `:region`, `:start_date`,
  `:end_date`, `:exchange`). Nil values are dropped.
  """
  @spec get(client(), keyword()) :: response()
  def get(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/calendar", params: Enum.reject(opts, fn {_, v} -> is_nil(v) end))
    |> Client.handle_response()
  end
end
