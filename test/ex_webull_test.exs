defmodule ExWebullTest do
  use ExUnit.Case, async: true

  test "new/3 delegates to Client.new/3 and attaches auth" do
    client = ExWebull.new("ak", "sk")
    assert client.options[:webull_app_key] == "ak"
    assert client.options[:webull_app_secret] == "sk"
    assert client.options.base_url == ExWebull.Client.base_url()
  end

  test "new_market_data/3 delegates to Client.new_market_data/3" do
    client = ExWebull.new_market_data("ak", "sk")
    assert client.options[:webull_app_key] == "ak"
    assert client.options.base_url == ExWebull.Client.market_data_base_url()
  end
end
