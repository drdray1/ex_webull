defmodule ExWebull.Trading do
  @moduledoc """
  Order placement and query — `/openapi/trade/order/*`.

  One set of endpoints covers every asset class. Orders are
  differentiated by `instrument_type`: `EQUITY`, `OPTION`, `FUTURES`,
  `CRYPTO`, or `EVENT`.

  ## Placing an option order

  Option orders carry an `option_strategy` and a `legs` array. See the
  strategy list in `ExWebull.Options` for what `option_strategy` accepts.

      ExWebull.Trading.place_order(client, "ACC-1", %{
        client_order_id: "my-unique-id",
        combo_type: "NORMAL",
        instrument_type: "OPTION",
        option_strategy: "SINGLE",
        market: "US",
        symbol: "AAPL",
        side: "BUY",
        order_type: "LIMIT",
        limit_price: "11.25",
        quantity: "1",
        entrust_type: "QTY",
        time_in_force: "DAY",
        legs: [
          %{
            side: "BUY",
            quantity: "1",
            symbol: "AAPL",
            strike_price: "220.00",
            option_expire_date: "2026-06-19",
            instrument_type: "OPTION",
            option_type: "CALL",
            market: "US"
          }
        ]
      })

  ## Reading option trades

  `order_history/3`, `open_orders/3`, and `order_detail/3` return combo
  orders whose `orders[].legs[]` carry full contract detail — strike,
  expiration, option type, multiplier — alongside `filled_quantity`,
  `filled_price`, `filled_time_at`, and `position_intent`.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  # ---- Placement ----------------------------------------------------------

  @doc """
  Places one or more orders (`POST /openapi/trade/order/place`).

  `new_orders` is an order map or a list of them. Pass
  `:client_combo_order_id` when `combo_type` is not `NORMAL`; the server
  generates one otherwise.
  """
  @spec place_order(client(), String.t(), map() | [map()], keyword()) :: response()
  def place_order(client, account_id, new_orders, opts \\ []) do
    Request.post(client, "/openapi/trade/order/place", %{
      account_id: account_id,
      client_combo_order_id: Keyword.get(opts, :client_combo_order_id),
      new_orders: List.wrap(new_orders)
    })
  end

  @doc """
  Previews orders before placement (`POST /openapi/trade/order/preview`).

  Returns estimated amount and cost. Not supported for crypto.
  """
  @spec preview_order(client(), String.t(), map() | [map()], keyword()) :: response()
  def preview_order(client, account_id, new_orders, opts \\ []) do
    Request.post(client, "/openapi/trade/order/preview", %{
      account_id: account_id,
      client_combo_order_id: Keyword.get(opts, :client_combo_order_id),
      new_orders: List.wrap(new_orders)
    })
  end

  @doc """
  Submits up to 50 orders at once (`POST /openapi/trade/order/batch-place`).

  Stocks only, and not enabled for all accounts.
  """
  @spec batch_place_orders(client(), String.t(), [map()]) :: response()
  def batch_place_orders(client, account_id, batch_orders) do
    Request.post(client, "/openapi/trade/order/batch-place", %{
      account_id: account_id,
      batch_orders: List.wrap(batch_orders)
    })
  end

  @doc """
  Modifies open orders (`POST /openapi/trade/order/replace`).

  Equities, options, and futures. Not supported for crypto.
  """
  @spec replace_order(client(), String.t(), map() | [map()]) :: response()
  def replace_order(client, account_id, modify_orders) do
    Request.post(client, "/openapi/trade/order/replace", %{
      account_id: account_id,
      modify_orders: List.wrap(modify_orders)
    })
  end

  @doc "Cancels an order by client order id (`POST /openapi/trade/order/cancel`)."
  @spec cancel_order(client(), String.t(), String.t()) :: response()
  def cancel_order(client, account_id, client_order_id) do
    Request.post(client, "/openapi/trade/order/cancel", %{
      account_id: account_id,
      client_order_id: client_order_id
    })
  end

  # ---- Query --------------------------------------------------------------

  @doc """
  Order history (`GET /openapi/trade/order/history`).

  Defaults to the last 7 days. Group orders are returned together, so a
  page may contain more than `:page_size` orders.

  ## Options

    - `:start_date` / `:end_date` — `yyyy-MM-dd`. The earliest available
      start date is `2018-05-21`.
    - `:page_size` — default 10, max 100.
    - `:last_client_order_id` — cursor from the previous page.
  """
  @spec order_history(client(), String.t(), keyword()) :: response()
  def order_history(client, account_id, opts \\ []) do
    Request.get(client, "/openapi/trade/order/history",
      account_id: account_id,
      start_date: opts[:start_date],
      end_date: opts[:end_date],
      page_size: opts[:page_size],
      last_client_order_id: opts[:last_client_order_id]
    )
  end

  @doc """
  Pending orders (`GET /openapi/trade/order/open`).

  May lag behind real time; use `order_detail/3` for the current status
  of a specific order.

  ## Options

    - `:page_size` — default 10, max 100.
    - `:last_client_order_id` — cursor from the previous page.
  """
  @spec open_orders(client(), String.t(), keyword()) :: response()
  def open_orders(client, account_id, opts \\ []) do
    Request.get(client, "/openapi/trade/order/open",
      account_id: account_id,
      page_size: opts[:page_size],
      last_client_order_id: opts[:last_client_order_id]
    )
  end

  @doc "Order detail by client order id (`GET /openapi/trade/order/detail`)."
  @spec order_detail(client(), String.t(), String.t()) :: response()
  def order_detail(client, account_id, client_order_id) do
    Request.get(client, "/openapi/trade/order/detail",
      account_id: account_id,
      client_order_id: client_order_id
    )
  end

  @doc """
  Account activity records (`GET /openapi/trading/activity/list`).

  The settlement-side ledger — trades, commissions, fees, journals,
  interest — for reconciling against what `order_history/3` reports.

  ## Options

    - `:activity_types` — one of `"TRADE"`, `"DEPOSIT"`, `"WITHDRAW"`,
      `"FEES"`, `"JOURNAL"`, `"INTERESTS"`, `"EC_STATEMENT"`.
    - `:start_time` / `:end_time` — ISO8601 UTC,
      `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`. Defaults to the last 7 days.
    - `:page_size` — default 10, range 1–200.
    - `:last_activity_id` — cursor from the previous page.
  """
  @spec activities(client(), String.t(), keyword()) :: response()
  def activities(client, account_id, opts \\ []) do
    Request.get(client, "/openapi/trading/activity/list",
      account_id: account_id,
      activity_types: opts[:activity_types],
      start_time: opts[:start_time],
      end_time: opts[:end_time],
      page_size: opts[:page_size],
      last_activity_id: opts[:last_activity_id]
    )
  end
end
