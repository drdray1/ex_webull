defmodule ExWebull.Client do
  @moduledoc """
  HTTP client factory for the Webull OpenAPI.

  Returns a `Req.Request.t()` preconfigured with base URL, JSON content
  type, transient retry, the required `x-version` header, an optional
  access token, and an attached HMAC-SHA1 signer.

  ## Two hosts

  Webull serves trading and market data from different hosts:

      trade = ExWebull.Client.new("app_key", "app_secret")
      md    = ExWebull.Client.new_market_data("app_key", "app_secret")

      {:ok, accounts} = ExWebull.Account.list(trade)
      {:ok, snap} = ExWebull.MarketData.Stock.snapshot(md, "AAPL")

  ## Access tokens

  Accounts with Two-Factor Authentication enabled must send an
  `x-access-token` header. Create one with `ExWebull.Token.create/1`,
  verify it in the Webull app, then pass it here:

      client = ExWebull.Client.new(key, secret, access_token: token)

  Without 2FA the header is unnecessary and can be omitted.
  """

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Creates a client pointed at the Trading API host.

  ## Options

    - `:access_token` — value for the `x-access-token` header.
    - `:base_url` — override the HTTP base URL (default from app config).
    - `:api_version` — `x-version` header value (default `"v2"`).
    - `:plug` — inject a `Req.Test` stub.
    - `:receive_timeout` — override receive timeout in ms.
  """
  @spec new(String.t() | nil, String.t() | nil, keyword()) :: client()
  def new(app_key, app_secret, opts \\ []) do
    headers =
      [
        {"content-type", "application/json"},
        {"x-version", Keyword.get(opts, :api_version, "v2")}
      ]
      |> maybe_token(Keyword.get(opts, :access_token))

    req_opts =
      [
        base_url: Keyword.get(opts, :base_url, base_url()),
        headers: headers,
        retry: :transient,
        max_retries: 3,
        retry_delay: fn attempt -> 500 * Integer.pow(2, attempt) end
      ]
      |> maybe_put(:plug, Keyword.get(opts, :plug))
      |> maybe_put(:receive_timeout, Keyword.get(opts, :receive_timeout))

    Req.new(req_opts) |> ExWebull.Auth.attach(app_key, app_secret)
  end

  @doc """
  Creates a client pointed at the Market Data API host.

  Accepts the same options as `new/3`; an explicit `:base_url` wins.
  """
  @spec new_market_data(String.t() | nil, String.t() | nil, keyword()) :: client()
  def new_market_data(app_key, app_secret, opts \\ []) do
    new(app_key, app_secret, Keyword.put_new(opts, :base_url, market_data_base_url()))
  end

  @doc "Returns the Trading API base URL from application config."
  @spec base_url() :: String.t()
  def base_url, do: config(:base_url, "https://api.webull.com")

  @doc "Returns the Market Data API base URL from application config."
  @spec market_data_base_url() :: String.t()
  def market_data_base_url,
    do: config(:market_data_base_url, "https://broker-api.webull.com")

  @doc "Returns the MQTT streaming host/port tuple from application config."
  @spec mqtt_endpoint() :: {String.t(), non_neg_integer()}
  def mqtt_endpoint do
    {config(:mqtt_host, "data-api.webull.com"), config(:mqtt_port, 1883)}
  end

  @doc "Returns the trade-events gRPC host/port tuple."
  @spec trade_events_endpoint() :: {String.t(), non_neg_integer()}
  def trade_events_endpoint do
    {config(:trade_events_host, "events-api.webull.com"), config(:trade_events_port, 443)}
  end

  @doc "Returns the default region id (`\"US\"`)."
  @spec region() :: String.t()
  def region, do: config(:region, "US")

  @doc """
  Unwraps a Webull API response into `{:ok, body}` / `{:error, reason}`.

  Successful responses are returned as-is — Webull does not wrap them in
  a universal envelope. 4xx and 5xx responses are mapped to tagged error
  tuples, with the body exposed under `{:api_error, status, body}`.
  """
  @spec handle_response({:ok, Req.Response.t()} | {:error, term()}) :: response()
  def handle_response({:ok, %Req.Response{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  def handle_response({:ok, %Req.Response{status: 401, body: body}}),
    do: {:error, {:unauthorized, body}}

  def handle_response({:ok, %Req.Response{status: 403, body: body}}),
    do: {:error, {:forbidden, body}}

  def handle_response({:ok, %Req.Response{status: 404, body: body}}),
    do: {:error, {:not_found, body}}

  def handle_response({:ok, %Req.Response{status: 429, body: body}}),
    do: {:error, {:rate_limited, body}}

  def handle_response({:ok, %Req.Response{status: status, body: body}}) when status >= 400 do
    {:error, {:api_error, status, body}}
  end

  def handle_response({:error, reason}), do: {:error, {:connection_error, reason}}

  defp config(key, default) do
    Application.get_env(:ex_webull, :config, []) |> Keyword.get(key, default)
  end

  defp maybe_token(headers, nil), do: headers
  defp maybe_token(headers, token), do: headers ++ [{"x-access-token", token}]

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
