defmodule ExWebull.Grpc.Auth do
  @moduledoc """
  Builds signed gRPC metadata for Webull OpenAPI calls.

  gRPC signing is nearly identical to HTTP signing
  (see `ExWebull.Auth`) with two differences:

    - No query parameters participate in the signature.
    - Body MD5 is **lowercase** hex (not uppercase as HTTP uses).
  """

  @signature_algorithm "HMAC-SHA1"
  @signature_version "1.0"

  @doc """
  Builds the metadata map for a gRPC request. Returns a map of
  lowercase header names to string values, ready to pass as
  `metadata: meta` to `GRPC.Stub.*` call functions.

  `uri` is the inner request path (e.g. `/market-data/snapshot`).
  `payload` is the serialized protobuf bytes (or `nil` for pings).
  """
  @spec build_metadata(String.t(), String.t(), String.t(), String.t(), binary() | nil) :: map()
  def build_metadata(app_key, app_secret, host, uri, payload) do
    timestamp = ExWebull.Auth.generate_timestamp()
    nonce = ExWebull.Auth.generate_nonce()

    sign_params = %{
      "host" => host,
      "x-app-key" => app_key,
      "x-signature-algorithm" => @signature_algorithm,
      "x-signature-version" => @signature_version,
      "x-signature-nonce" => nonce,
      "x-timestamp" => timestamp
    }

    body_md5 = grpc_body_md5(payload)
    sign_string = build_sign_string(sign_params, uri, body_md5)
    encoded = url_encode(sign_string)

    signature =
      :crypto.mac(:hmac, :sha, app_secret <> "&", encoded) |> Base.encode64()

    %{
      "x-app-key" => app_key,
      "x-signature-algorithm" => @signature_algorithm,
      "x-signature-version" => @signature_version,
      "x-signature-nonce" => nonce,
      "x-timestamp" => timestamp,
      "x-signature" => signature
    }
  end

  defp grpc_body_md5(nil), do: nil
  defp grpc_body_md5(""), do: nil

  defp grpc_body_md5(bytes) when is_binary(bytes) do
    :crypto.hash(:md5, bytes) |> Base.encode16(case: :lower)
  end

  defp build_sign_string(sign_params, uri, body_md5) do
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

    case body_md5 do
      nil -> base
      md5 -> base <> "&" <> md5
    end
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
