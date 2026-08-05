defmodule ExWebull.Assets do
  @moduledoc """
  Account balances and positions — `/openapi/assets/*`.

  Option positions carry an `"option_strategy"` and a `"legs"` array
  describing the contracts held:

      %{
        "position_id" => "...",
        "symbol" => "AAPL",
        "instrument_type" => "OPTION",
        "option_strategy" => "SINGLE",
        "quantity" => "1",
        "cost_price" => "3.42",
        "last_price" => "4.10",
        "unrealized_profit_loss" => "68.00",
        "legs" => [
          %{
            "leg_id" => "...",
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
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Account balance and buying power (`GET /openapi/assets/balance`)."
  @spec balance(client(), String.t()) :: response()
  def balance(client, account_id),
    do: Request.get(client, "/openapi/assets/balance", account_id: account_id)

  @doc "Positions, with option legs (`GET /openapi/assets/positions`)."
  @spec positions(client(), String.t()) :: response()
  def positions(client, account_id),
    do: Request.get(client, "/openapi/assets/positions", account_id: account_id)
end
