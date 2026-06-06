defmodule ExWebull.Fixtures do
  @moduledoc false

  @doc """
  Builds a test client that routes through a `Req.Test` stub.

  Pass the result of calling this to modules like `ExWebull.Account`.
  """
  @spec test_client(atom()) :: Req.Request.t()
  def test_client(stub_name) do
    ExWebull.Client.new("test-key", "test-secret", plug: {Req.Test, stub_name})
  end

  @doc "Returns a canned account-list response body."
  def account_list_response do
    %{
      "accounts" => [
        %{"account_id" => "ACC-1", "account_type" => "MARGIN"},
        %{"account_id" => "ACC-2", "account_type" => "CASH"}
      ]
    }
  end

  @doc "Returns a canned balance response body."
  def balance_response do
    %{
      "account_id" => "ACC-1",
      "net_liquidation_value" => "10000.00",
      "buying_power" => "20000.00",
      "cash_balance" => "5000.00"
    }
  end

  @doc "Returns a canned error response body."
  def error_response(code \\ "40001", msg \\ "Invalid parameter") do
    %{"code" => code, "msg" => msg}
  end
end
