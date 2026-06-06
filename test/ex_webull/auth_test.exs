defmodule ExWebull.AuthTest do
  use ExUnit.Case, async: true

  alias ExWebull.Auth

  describe "compute_signature/4" do
    test "matches Python SDK reference vector with body" do
      sign_params = %{
        "x-app-key" => "test-app-key",
        "x-timestamp" => "2026-04-23T12:00:00Z",
        "x-signature-version" => "1.0",
        "x-signature-algorithm" => "HMAC-SHA1",
        "x-signature-nonce" => "nonce-1234567890",
        "host" => "api.webull.com",
        "symbols" => "AAPL",
        "category" => "US_STOCK"
      }

      body = ~s({"k1":123,"k2":"hello","k3":true})
      uri = "/trade/v2/orders/place"

      assert Auth.compute_signature(sign_params, uri, body, "test-secret") ==
               "fjeBpIhs50Kk7QbZfNL8PMGyx9g="
    end

    test "matches Python SDK reference vector without body" do
      sign_params = %{
        "x-app-key" => "test-app-key",
        "x-timestamp" => "2026-04-23T12:00:00Z",
        "x-signature-version" => "1.0",
        "x-signature-algorithm" => "HMAC-SHA1",
        "x-signature-nonce" => "nonce-1234567890",
        "host" => "api.webull.com",
        "symbols" => "AAPL",
        "category" => "US_STOCK"
      }

      uri = "/trade/v2/orders/place"

      assert Auth.compute_signature(sign_params, uri, nil, "test-secret") ==
               "lUGK3ugdCsISVsEyluvX/iEMP6M="

      assert Auth.compute_signature(sign_params, uri, "", "test-secret") ==
               "lUGK3ugdCsISVsEyluvX/iEMP6M="
    end
  end

  describe "generate_timestamp/0" do
    test "produces ISO-8601 UTC seconds-precision string ending in Z" do
      ts = Auth.generate_timestamp()
      assert ts =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
    end
  end

  describe "generate_nonce/0" do
    test "produces a 32-char lowercase hex string" do
      nonce = Auth.generate_nonce()
      assert byte_size(nonce) == 32
      assert nonce =~ ~r/^[0-9a-f]{32}$/
    end

    test "returns unique values across calls" do
      refute Auth.generate_nonce() == Auth.generate_nonce()
    end
  end

  describe "attach/3" do
    test "appends signing step to the request" do
      req = Req.new(base_url: "https://api.webull.com") |> Auth.attach("ak", "sk")
      assert req.options[:webull_app_key] == "ak"
      assert req.options[:webull_app_secret] == "sk"
      assert Keyword.has_key?(req.request_steps, :webull_auth)
    end

    test "stores nil credentials without failing" do
      req = Req.new() |> Auth.attach(nil, nil)
      assert req.options[:webull_app_key] == nil
      assert req.options[:webull_app_secret] == nil
    end
  end
end
