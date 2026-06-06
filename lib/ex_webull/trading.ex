defmodule ExWebull.Trading do
  @moduledoc """
  Webull v2 Trading endpoints — place, replace, cancel, preview, and
  query orders (both equities and options).
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  # ---- Equity orders ------------------------------------------------------

  @doc """
  Places one or more equity orders (`POST /openapi/account/orders/place`).

  `new_orders` is a list of order maps (or a single order map, which is
  wrapped into a list).
  """
  @spec place_order(client(), String.t(), map() | [map()]) :: response()
  def place_order(client, account_id, new_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/place",
      params: [account_id: account_id],
      json: %{new_orders: wrap_list(new_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Previews equity orders before placement (`POST /openapi/account/orders/preview`)."
  @spec preview_order(client(), String.t(), map() | [map()]) :: response()
  def preview_order(client, account_id, new_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/preview",
      params: [account_id: account_id],
      json: %{new_orders: wrap_list(new_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Replaces equity orders (`POST /openapi/account/orders/replace`)."
  @spec replace_order(client(), String.t(), map() | [map()]) :: response()
  def replace_order(client, account_id, modify_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/replace",
      params: [account_id: account_id],
      json: %{modify_orders: wrap_list(modify_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Cancels an equity order by client order id (`POST /openapi/account/orders/cancel`)."
  @spec cancel_order(client(), String.t(), String.t()) :: response()
  def cancel_order(client, account_id, client_order_id) do
    client
    |> Req.post(
      url: "/openapi/account/orders/cancel",
      params: [account_id: account_id],
      json: %{client_order_id: client_order_id}
    )
    |> Client.handle_response()
  end

  @doc """
  Gets order detail (`GET /openapi/account/orders/detail`).
  """
  @spec order_detail(client(), String.t(), String.t()) :: response()
  def order_detail(client, account_id, client_order_id) do
    client
    |> Req.get(
      url: "/openapi/account/orders/detail",
      params: [account_id: account_id, client_order_id: client_order_id]
    )
    |> Client.handle_response()
  end

  @doc """
  Gets order history, past 7 days (`GET /openapi/account/orders/history`).

  ## Options

    - `:page_size` — default 10
    - `:start_date` / `:end_date` — format `yyyy-MM-dd`
    - `:last_client_order_id` — pagination cursor
  """
  @spec order_history(client(), String.t(), keyword()) :: response()
  def order_history(client, account_id, opts \\ []) do
    params =
      [account_id: account_id]
      |> Keyword.merge(
        opts
        |> Keyword.take([:page_size, :start_date, :end_date, :last_client_order_id])
        |> drop_nil()
      )

    client
    |> Req.get(url: "/openapi/account/orders/history", params: params)
    |> Client.handle_response()
  end

  @doc "Open orders for today (`GET /trade/orders/list-open`, legacy v1)."
  @spec open_orders(client(), keyword()) :: response()
  def open_orders(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/orders/list-open", params: drop_nil(opts))
    |> Client.handle_response()
  end

  @doc "Today's orders (`GET /trade/orders/list-today`, legacy v1)."
  @spec today_orders(client(), keyword()) :: response()
  def today_orders(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/orders/list-today", params: drop_nil(opts))
    |> Client.handle_response()
  end

  # ---- Option orders ------------------------------------------------------

  @doc "Places option orders (`POST /openapi/account/orders/option/place`)."
  @spec place_option(client(), String.t(), map() | [map()]) :: response()
  def place_option(client, account_id, new_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/option/place",
      params: [account_id: account_id],
      json: %{new_orders: wrap_list(new_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Previews option orders (`POST /openapi/account/orders/option/preview`)."
  @spec preview_option(client(), String.t(), map() | [map()]) :: response()
  def preview_option(client, account_id, new_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/option/preview",
      params: [account_id: account_id],
      json: %{new_orders: wrap_list(new_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Replaces option orders (`POST /openapi/account/orders/option/replace`)."
  @spec replace_option(client(), String.t(), map() | [map()]) :: response()
  def replace_option(client, account_id, modify_orders) do
    client
    |> Req.post(
      url: "/openapi/account/orders/option/replace",
      params: [account_id: account_id],
      json: %{modify_orders: wrap_list(modify_orders)}
    )
    |> Client.handle_response()
  end

  @doc "Cancels an option order (`POST /openapi/account/orders/option/cancel`)."
  @spec cancel_option(client(), String.t(), String.t()) :: response()
  def cancel_option(client, account_id, client_order_id) do
    client
    |> Req.post(
      url: "/openapi/account/orders/option/cancel",
      params: [account_id: account_id],
      json: %{client_order_id: client_order_id}
    )
    |> Client.handle_response()
  end

  defp wrap_list(list) when is_list(list), do: list
  defp wrap_list(map) when is_map(map), do: [map]

  defp drop_nil(kw), do: Enum.reject(kw, fn {_k, v} -> is_nil(v) end)
end
