defmodule ExWebull.Grpc.AuthTest do
  use ExUnit.Case, async: true

  describe "build_metadata/5" do
    test "returns signed metadata map with required keys" do
      meta =
        ExWebull.Grpc.Auth.build_metadata(
          "ak",
          "sk",
          "api.webull.com",
          "/market-data/snapshot",
          nil
        )

      assert Map.has_key?(meta, "x-app-key")
      assert Map.has_key?(meta, "x-timestamp")
      assert Map.has_key?(meta, "x-signature")
      assert Map.has_key?(meta, "x-signature-algorithm")
      assert Map.has_key?(meta, "x-signature-version")
      assert Map.has_key?(meta, "x-signature-nonce")
      assert meta["x-app-key"] == "ak"
      assert meta["x-signature-algorithm"] == "HMAC-SHA1"
    end

    test "each call produces a fresh nonce + timestamp" do
      m1 = ExWebull.Grpc.Auth.build_metadata("ak", "sk", "h", "/p", nil)
      m2 = ExWebull.Grpc.Auth.build_metadata("ak", "sk", "h", "/p", nil)
      refute m1["x-signature-nonce"] == m2["x-signature-nonce"]
    end
  end
end
