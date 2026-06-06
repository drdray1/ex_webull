defmodule ExWebull.TradeEvents.Auth do
  @moduledoc """
  Builds signed gRPC metadata for the trade-events Subscribe stream.

  Differs from `ExWebull.Grpc.Auth`:

    - No `host` participates in the sign params.
    - No URI (the sign string is built without a URI prefix).
    - Body MD5 is lowercase hex.

  Important: when URI is empty, the Webull reference composer joins
  pairs with `"="` rather than `"&"` — we preserve that quirk so the
  resulting signature matches the Python SDK.
  """

  @signature_algorithm "HMAC-SHA1"
  @signature_version "1.0"

  @doc "Builds signed metadata for a `SubscribeRequest`."
  @spec build_metadata(String.t(), String.t(), binary()) :: map()
  def build_metadata(app_key, app_secret, payload) when is_binary(payload) do
    timestamp = ExWebull.Auth.generate_timestamp()
    nonce = ExWebull.Auth.generate_nonce()

    sign_params = %{
      "x-app-key" => app_key,
      "x-signature-algorithm" => @signature_algorithm,
      "x-signature-version" => @signature_version,
      "x-signature-nonce" => nonce,
      "x-timestamp" => timestamp
    }

    body_md5 = if payload == "", do: nil, else: lowercase_md5(payload)
    sign_string = build_sign_string(sign_params, body_md5)
    encoded = url_encode(sign_string)
    signature = :crypto.mac(:hmac, :sha, app_secret <> "&", encoded) |> Base.encode64()

    %{
      "x-app-key" => app_key,
      "x-signature-algorithm" => @signature_algorithm,
      "x-signature-version" => @signature_version,
      "x-signature-nonce" => nonce,
      "x-timestamp" => timestamp,
      "x-signature" => signature
    }
  end

  defp build_sign_string(sign_params, body_md5) do
    sorted =
      sign_params
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)

    # Preserve Webull Python SDK quirk: when URI is absent, pairs are
    # joined with "=" rather than "&".
    base = Enum.join(sorted, "=")

    case body_md5 do
      nil -> base
      md5 -> base <> "&" <> md5
    end
  end

  defp lowercase_md5(bytes) do
    :crypto.hash(:md5, bytes) |> Base.encode16(case: :lower)
  end

  defp url_encode(string) do
    URI.encode(string, fn c ->
      cond do
        c in ?A..?Z -> true
        c in ?a..?z -> true
        c in ?0..?9 -> true
        c in [?-, ?., ?_, ?~] -> true
        true -> false
      end
    end)
  end
end
