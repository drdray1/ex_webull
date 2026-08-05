defmodule ExWebull.Token do
  @moduledoc """
  Access token lifecycle for accounts with Two-Factor Authentication.

  Without 2FA these endpoints are unnecessary. With 2FA enabled every
  other API call must carry an `x-access-token` header.

      {:ok, %{"token" => token, "status" => "PENDING"}} =
        ExWebull.Token.create(client)

      # Verify the SMS code in the Webull app within 5 minutes, then:
      {:ok, %{"status" => "NORMAL"}} = ExWebull.Token.check(client, token)

      client = ExWebull.Client.new(key, secret, access_token: token)

  Statuses are `PENDING` (awaiting app verification), `NORMAL` (active),
  `EXPIRED` (not verified within 5 minutes), and `INVALID` (unused for
  15 consecutive days, or unknown). A valid token should be stored and
  reused rather than recreated per call.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Creates an access token (`POST /openapi/auth/token/create`).

  Returns a token with status `PENDING` and sends an SMS code to the
  phone number bound to the account. Tokens created in the test
  environment are valid immediately.
  """
  @spec create(client()) :: response()
  def create(client), do: Request.post(client, "/openapi/auth/token/create")

  @doc "Checks an access token's status (`POST /openapi/auth/token/check`)."
  @spec check(client(), String.t()) :: response()
  def check(client, token),
    do: Request.post(client, "/openapi/auth/token/check", %{token: token})
end
