defmodule ExWebull.Account do
  @moduledoc """
  Account endpoints.

  Balances and positions live in `ExWebull.Assets`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Lists the subscribed brokerage accounts (`GET /openapi/account/list`)."
  @spec list(client()) :: response()
  def list(client), do: Request.get(client, "/openapi/account/list")
end
