defmodule ExWebull.OAuth do
  @moduledoc """
  Connect API — OAuth 2.0 authorization for third-party integrations.

  Two steps: send the user to `authorize_url/2`, then exchange the
  returned `code` for tokens.

      url =
        ExWebull.OAuth.authorize_url("client_id",
          scope: "user,trade",
          state: "unguessable-random-string",
          redirect_uri: "https://example.com/callback"
        )

      {:ok, tokens} =
        ExWebull.OAuth.create_token(client, "client_id", "client_secret", code)

      {:ok, tokens} =
        ExWebull.OAuth.refresh_token(client, "client_id", "client_secret", refresh)
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Builds the authorization URL (`GET /oauth2/authenticate/login`).

  Returns a URL to redirect the user to; Webull calls back to
  `:redirect_uri` with a `code` once the user grants access.

  ## Options

    - `:scope` (required) — requested scopes, e.g. `"user,trade"`.
      Available scopes are `user`, `trade`, `wr` (write), `read`.
    - `:state` (required) — unguessable random string, echoed back to
      guard against request forgery.
    - `:redirect_uri` (required) — must match a whitelisted URI.
    - `:base_url` — override the host (defaults to the trading host).
  """
  @spec authorize_url(String.t(), keyword()) :: String.t()
  def authorize_url(client_id, opts) do
    query =
      URI.encode_query(
        response_type: "code",
        client_id: client_id,
        scope: Keyword.fetch!(opts, :scope),
        state: Keyword.fetch!(opts, :state),
        redirect_uri: Keyword.fetch!(opts, :redirect_uri)
      )

    base = Keyword.get(opts, :base_url, ExWebull.Client.base_url())
    "#{base}/oauth2/authenticate/login?#{query}"
  end

  @doc """
  Exchanges an authorization code for tokens (`POST /openapi/oauth2/token`).
  """
  @spec create_token(client(), String.t(), String.t(), String.t()) :: response()
  def create_token(client, client_id, client_secret, code) do
    Request.post(client, "/openapi/oauth2/token", %{
      client_id: client_id,
      client_secret: client_secret,
      grant_type: "authorization_code",
      code: code
    })
  end

  @doc "Refreshes an access token (`POST /openapi/oauth2/token`)."
  @spec refresh_token(client(), String.t(), String.t(), String.t()) :: response()
  def refresh_token(client, client_id, client_secret, refresh_token) do
    Request.post(client, "/openapi/oauth2/token", %{
      client_id: client_id,
      client_secret: client_secret,
      grant_type: "refresh_token",
      refresh_token: refresh_token
    })
  end
end
