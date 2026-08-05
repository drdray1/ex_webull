defmodule ExWebull.Fixtures do
  @moduledoc false

  @doc """
  Builds a test client that routes through a `Req.Test` stub.

  Pass the result to modules like `ExWebull.Account`.
  """
  @spec test_client(atom(), keyword()) :: Req.Request.t()
  def test_client(stub_name, opts \\ []) do
    ExWebull.Client.new("test-key", "test-secret", [plug: {Req.Test, stub_name}] ++ opts)
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

  @doc """
  Returns a canned combo-order entry for a single-leg option order,
  shaped like `GET /openapi/trade/order/history`.
  """
  def option_combo_order do
    %{
      "combo_order_id" => "CMB-1",
      "combo_type" => "NORMAL",
      "client_order_id" => "COID-1",
      "orders" => [
        %{
          "client_order_id" => "COID-1",
          "order_id" => "ORD-1",
          "symbol" => "AAPL",
          "instrument_type" => "OPTION",
          "option_strategy" => "SINGLE",
          "position_intent" => "BUY_TO_OPEN",
          "side" => "BUY",
          "status" => "FILLED",
          "order_type" => "LIMIT",
          "time_in_force" => "DAY",
          "total_quantity" => "1",
          "filled_quantity" => "1",
          "filled_price" => "3.42",
          "limit_price" => "3.50",
          "place_time_at" => "2026-01-02T14:30:00.000Z",
          "filled_time_at" => "2026-01-02T14:30:02.000Z",
          "legs" => [
            %{
              "id" => "LEG-1",
              "symbol" => "AAPL",
              "side" => "BUY",
              "quantity" => "1",
              "option_type" => "CALL",
              "option_category" => "AMERICAN",
              "strike_price" => "180.00",
              "option_expire_date" => "2026-06-19",
              "option_contract_multiplier" => "100",
              "option_contract_deliverable" => "100"
            }
          ]
        }
      ]
    }
  end

  @doc "Returns a canned option position entry."
  def option_position do
    %{
      "position_id" => "POS-1",
      "symbol" => "AAPL",
      "instrument_type" => "OPTION",
      "option_strategy" => "SINGLE",
      "currency" => "USD",
      "quantity" => "1",
      "cost_price" => "3.42",
      "last_price" => "4.10",
      "unrealized_profit_loss" => "68.00",
      "legs" => [
        %{
          "leg_id" => "LEG-1",
          "symbol" => "AAPL",
          "quantity" => "1",
          "option_type" => "CALL",
          "option_expire_date" => "2026-06-19",
          "option_exercise_price" => "180.00",
          "option_contract_multiplier" => "100",
          "option_contract_deliverable" => "100"
        }
      ]
    }
  end

  @doc "Returns a canned error response body."
  def error_response(code \\ "40001", msg \\ "Invalid parameter") do
    %{"code" => code, "msg" => msg}
  end
end
