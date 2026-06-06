defmodule ExWebull.TradeEvents.AuthTest do
  use ExUnit.Case, async: true

  alias ExWebull.TradeEvents.Auth

  test "build_metadata returns all signed keys" do
    meta = Auth.build_metadata("ak", "sk", <<1, 2, 3>>)

    assert meta["x-app-key"] == "ak"
    assert meta["x-signature-algorithm"] == "HMAC-SHA1"
    assert meta["x-signature-version"] == "1.0"
    assert is_binary(meta["x-signature-nonce"])
    assert meta["x-signature"] =~ ~r/^[A-Za-z0-9+\/=]+$/
  end

  test "build_metadata accepts empty payload (no body md5)" do
    meta = Auth.build_metadata("ak", "sk", "")
    assert is_binary(meta["x-signature"])
  end
end
