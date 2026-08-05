defmodule ExWebull.Auth do
  @moduledoc """
  Req plugin for Webull OpenAPI HMAC-SHA1 authentication.

  Automatically generates and attaches authentication headers to each
  request as required by the Webull OpenAPI.

  ## Headers

  Signed requests include these headers:

    - `x-app-key` — app key
    - `x-timestamp` — ISO-8601 UTC timestamp (`YYYY-MM-DDTHH:MM:SSZ`)
    - `x-signature-algorithm` — `HMAC-SHA1`
    - `x-signature-version` — `1.0`
    - `x-signature-nonce` — unique random UUID
    - `x-signature` — base64-encoded HMAC-SHA1 signature

  `x-version` and `x-access-token` are also required by the API but do
  **not** participate in the signature; `ExWebull.Client` sets them.

  ## Signature algorithm

  1. Collect sign params: lowercased `x-app-key`, `x-timestamp`,
     `x-signature-version`, `x-signature-algorithm`, `x-signature-nonce`,
     and `host`. Merge in query params (lowercased keys).
  2. Sort keys ascending. Build `k=v` pairs joined by `&` using the raw
     (unencoded) string values. If a query-param key collides with a
     sign-header key, the existing value is joined with the new via `&`.
  3. If a request body is present, compute
     `body_md5 = upper(hex(md5(compact_json_body)))`.
  4. Build `sign_string = uri + "&" + sorted_pairs + "&" + body_md5`
     (body segment omitted when there is no body).
  5. URL-encode the entire sign string (RFC 3986 strict — everything
     except `A-Za-z0-9-._~` is percent-encoded, and `/` is also encoded).
  6. `signature = base64(HMAC-SHA1(app_secret <> "&", encoded_sign_string))`.
  """

  @signature_algorithm "HMAC-SHA1"
  @signature_version "1.0"

  @sign_headers [
    "x-app-key",
    "x-timestamp",
    "x-signature-version",
    "x-signature-algorithm",
    "x-signature-nonce"
  ]

  @doc """
  Attaches HMAC-SHA1 authentication to a Req request.
  """
  @spec attach(Req.Request.t(), String.t() | nil, String.t() | nil) :: Req.Request.t()
  def attach(request, app_key, app_secret) do
    request
    |> Req.Request.register_options([:webull_app_key, :webull_app_secret])
    |> Req.Request.merge_options(webull_app_key: app_key, webull_app_secret: app_secret)
    |> Req.Request.append_request_steps(webull_auth: &sign_request/1)
  end

  @doc """
  Computes the HMAC-SHA1 signature for given request components.

  Exposed for testing and for gRPC/MQTT reuse.

  `sign_params` is a map of lowercased string keys to string values. It
  must already include the sign headers (`x-app-key`, `x-timestamp`,
  `x-signature-version`, `x-signature-algorithm`, `x-signature-nonce`,
  `host`) and any query params. Body should be a JSON-serialized string
  or `nil`.
  """
  @spec compute_signature(map(), String.t(), String.t() | nil, String.t()) :: String.t()
  def compute_signature(sign_params, uri, body, app_secret) do
    sign_string = build_sign_string(sign_params, uri, body)

    encoded = url_encode(sign_string)

    :crypto.mac(:hmac, :sha, app_secret <> "&", encoded)
    |> Base.encode64()
  end

  @doc "Generates an ISO-8601 UTC timestamp string (`YYYY-MM-DDTHH:MM:SSZ`)."
  @spec generate_timestamp() :: String.t()
  def generate_timestamp do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  @doc "Generates a UUID-style random nonce (32-hex-char string, no dashes)."
  @spec generate_nonce() :: String.t()
  def generate_nonce do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  @doc false
  @spec sign_headers() :: [String.t()]
  def sign_headers, do: @sign_headers

  defp sign_request(request) do
    app_key = request.options[:webull_app_key]
    app_secret = request.options[:webull_app_secret]

    if app_key && app_secret do
      do_sign(request, app_key, app_secret)
    else
      request
    end
  end

  defp do_sign(request, app_key, app_secret) do
    timestamp = generate_timestamp()
    nonce = generate_nonce()
    host = extract_host(request)
    uri = extract_uri(request)
    body = extract_body(request)
    query = extract_query(request)

    sign_params =
      %{
        "x-app-key" => app_key,
        "x-timestamp" => timestamp,
        "x-signature-algorithm" => @signature_algorithm,
        "x-signature-version" => @signature_version,
        "x-signature-nonce" => nonce,
        "host" => host
      }
      |> merge_query(query)

    signature = compute_signature(sign_params, uri, body, app_secret)

    request
    |> Req.Request.put_header("x-app-key", app_key)
    |> Req.Request.put_header("x-timestamp", timestamp)
    |> Req.Request.put_header("x-signature-algorithm", @signature_algorithm)
    |> Req.Request.put_header("x-signature-version", @signature_version)
    |> Req.Request.put_header("x-signature-nonce", nonce)
    |> Req.Request.put_header("x-signature", signature)
  end

  @spec build_sign_string(map(), String.t(), String.t() | nil) :: String.t()
  defp build_sign_string(sign_params, uri, body) do
    sorted =
      sign_params
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map_join("&", fn {k, v} -> "#{k}=#{v}" end)

    base =
      case uri do
        nil -> sorted
        "" -> sorted
        _ -> uri <> "&" <> sorted
      end

    case body_md5(body) do
      nil -> base
      md5 -> base <> "&" <> md5
    end
  end

  @spec body_md5(String.t() | nil) :: String.t() | nil
  defp body_md5(nil), do: nil
  defp body_md5(""), do: nil

  defp body_md5(body) when is_binary(body) do
    :crypto.hash(:md5, body) |> Base.encode16(case: :upper)
  end

  @spec url_encode(String.t()) :: String.t()
  defp url_encode(string) do
    URI.encode(string, &unreserved?/1)
  end

  defp unreserved?(c)
       when c in ?A..?Z
       when c in ?a..?z
       when c in ?0..?9
       when c in [?-, ?., ?_, ?~],
       do: true

  defp unreserved?(_), do: false

  defp extract_uri(request) do
    case request.url do
      %URI{path: path} when is_binary(path) -> path
      _ -> ""
    end
  end

  defp extract_host(request) do
    case request.url do
      %URI{host: host} when is_binary(host) -> host
      _ -> ""
    end
  end

  defp extract_query(%{url: %URI{query: nil}}), do: %{}

  defp extract_query(%{url: %URI{query: q}}) when is_binary(q) do
    URI.decode_query(q)
  end

  defp extract_query(_), do: %{}

  defp extract_body(%{body: nil}), do: nil
  defp extract_body(%{body: ""}), do: nil
  defp extract_body(%{body: body}) when is_binary(body), do: body

  # Req encodes JSON into iodata before request steps run, so a `json:`
  # body reaches the signer already serialized.
  defp extract_body(%{body: body}) when is_list(body), do: IO.iodata_to_binary(body)

  # Streamed and enumerable bodies cannot be hashed up front; they sign
  # as if there were no body.
  defp extract_body(_), do: nil

  defp merge_query(sign_params, query) when query == %{}, do: sign_params

  defp merge_query(sign_params, query) do
    Enum.reduce(query, sign_params, fn {k, v}, acc ->
      lk = String.downcase(k)

      case Map.get(acc, lk) do
        nil -> Map.put(acc, lk, to_string(v))
        existing -> Map.put(acc, lk, "#{existing}&#{v}")
      end
    end)
  end
end
