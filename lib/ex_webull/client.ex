defmodule ExWebull.Client do
  @moduledoc """
  HTTP client factory for the Webull OpenAPI.

  Returns a `Req.Request.t()` preconfigured with base URL, JSON content
  type, transient retry, and an attached HMAC-SHA1 signer.

  ## Usage

      client = ExWebull.Client.new("app_key", "app_secret")
      {:ok, data} = ExWebull.Account.list(client)

      # Testing with Req.Test
      client = ExWebull.Client.new("ak", "sk", plug: {Req.Test, MyStub})
  """

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Creates a new Webull API client.

  ## Options

    - `:base_url` — override the HTTP base URL (default from app config).
    - `:plug` — inject a `Req.Test` stub.
    - `:receive_timeout` — override receive timeout in ms.
  """
  @spec new(String.t() | nil, String.t() | nil, keyword()) :: client()
  def new(app_key, app_secret, opts \\ []) do
    req_opts =
      [
        base_url: Keyword.get(opts, :base_url, base_url()),
        headers: [{"content-type", "application/json"}],
        retry: :transient,
        max_retries: 3,
        retry_delay: fn attempt -> 500 * Integer.pow(2, attempt) end
      ]
      |> maybe_put(:plug, Keyword.get(opts, :plug))
      |> maybe_put(:receive_timeout, Keyword.get(opts, :receive_timeout))

    Req.new(req_opts) |> ExWebull.Auth.attach(app_key, app_secret)
  end

  @doc "Returns the HTTP base URL from application config."
  @spec base_url() :: String.t()
  def base_url do
    config = Application.get_env(:ex_webull, :config, [])
    Keyword.get(config, :base_url, "https://api.webull.com")
  end

  @doc "Returns the MQTT host/port tuple from application config."
  @spec mqtt_endpoint() :: {String.t(), non_neg_integer()}
  def mqtt_endpoint do
    config = Application.get_env(:ex_webull, :config, [])

    {
      Keyword.get(config, :mqtt_host, "usquotes-api.webullfintech.com"),
      Keyword.get(config, :mqtt_port, 8883)
    }
  end

  @doc "Returns the gRPC quotes host/port tuple from application config."
  @spec quotes_grpc_endpoint() :: {String.t(), non_neg_integer()}
  def quotes_grpc_endpoint do
    config = Application.get_env(:ex_webull, :config, [])

    {
      Keyword.get(config, :quotes_host, "api.webull.com"),
      Keyword.get(config, :quotes_port, 443)
    }
  end

  @doc "Returns the trade-events gRPC host/port tuple."
  @spec trade_events_endpoint() :: {String.t(), non_neg_integer()}
  def trade_events_endpoint do
    config = Application.get_env(:ex_webull, :config, [])

    {
      Keyword.get(config, :trade_events_host, "events-api.webull.com"),
      Keyword.get(config, :trade_events_port, 443)
    }
  end

  @doc "Returns the default region id (`\"US\"`)."
  @spec region() :: String.t()
  def region do
    config = Application.get_env(:ex_webull, :config, [])
    Keyword.get(config, :region, "US")
  end

  @doc """
  Unwraps a Webull API response into `{:ok, body}` / `{:error, reason}`.

  Webull's successful responses are returned as-is (they do not wrap a
  universal envelope the way BloFin does). 4xx and 5xx responses are
  mapped to tagged error tuples, and the body is exposed under
  `{:api_error, status, body}`.
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

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
