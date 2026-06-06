defmodule ExWebullTest do
  use ExUnit.Case, async: true

  test "new/3 delegates to Client.new/3 and attaches auth" do
    client = ExWebull.new("ak", "sk")
    assert client.options[:webull_app_key] == "ak"
    assert client.options[:webull_app_secret] == "sk"
  end
end
