defmodule ExWebull.TradingTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"trading_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp version(conn), do: Plug.Conn.get_req_header(conn, "x-version")

  test "place_order/4 wraps a single order and omits an unset combo id", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/trade/order/place"
      assert version(conn) == ["v2"]
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["account_id"] == "ACC-1"
      assert [%{"symbol" => "AAPL"}] = payload["new_orders"]
      refute Map.has_key?(payload, "client_combo_order_id")
      Req.Test.json(conn, %{"client_order_id" => "COID-1"})
    end)

    assert {:ok, %{"client_order_id" => "COID-1"}} =
             ExWebull.Trading.place_order(client, "ACC-1", %{symbol: "AAPL", quantity: "1"})
  end

  test "place_order/4 forwards a combo id and a list of orders", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["client_combo_order_id"] == "CMB-1"
      assert [%{"symbol" => "AAPL"}, %{"symbol" => "TSLA"}] = payload["new_orders"]
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.place_order(
      client,
      "ACC-1",
      [%{symbol: "AAPL"}, %{symbol: "TSLA"}],
      client_combo_order_id: "CMB-1"
    )
  end

  test "place_order/4 sends option legs through", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"new_orders" => [order]} = Jason.decode!(body)
      assert order["instrument_type"] == "OPTION"
      assert order["option_strategy"] == "SINGLE"
      assert [%{"option_type" => "CALL", "strike_price" => "220.00"}] = order["legs"]
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.place_order(client, "ACC-1", %{
      instrument_type: "OPTION",
      option_strategy: "SINGLE",
      symbol: "AAPL",
      legs: [%{option_type: "CALL", strike_price: "220.00", option_expire_date: "2026-06-19"}]
    })
  end

  test "preview_order/4 targets the preview path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/preview"
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.preview_order(client, "ACC-1", %{symbol: "AAPL"})
  end

  test "batch_place_orders/3 posts batch_orders", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/batch-place"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"batch_orders" => [_, _]} = Jason.decode!(body)
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.batch_place_orders(client, "ACC-1", [%{symbol: "AAPL"}, %{symbol: "TSLA"}])
  end

  test "replace_order/3 posts modify_orders", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/replace"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"modify_orders" => [%{"client_order_id" => "X"}]} = Jason.decode!(body)
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.replace_order(client, "ACC-1", %{client_order_id: "X"})
  end

  test "cancel_order/3 posts account and client order ids", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/cancel"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"account_id" => "ACC-1", "client_order_id" => "COID-1"} = Jason.decode!(body)
      Req.Test.json(conn, %{"ok" => true})
    end)

    assert {:ok, _} = ExWebull.Trading.cancel_order(client, "ACC-1", "COID-1")
  end

  test "order_history/3 forwards paging options and returns option legs", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/openapi/trade/order/history"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "page_size=100"
      assert q =~ "start_date=2026-01-01"
      assert q =~ "end_date=2026-01-31"
      assert q =~ "last_client_order_id=COID-9"
      Req.Test.json(conn, [option_combo_order()])
    end)

    assert {:ok, [combo]} =
             ExWebull.Trading.order_history(client, "ACC-1",
               page_size: 100,
               start_date: "2026-01-01",
               end_date: "2026-01-31",
               last_client_order_id: "COID-9"
             )

    assert [%{"instrument_type" => "OPTION", "legs" => [leg]}] = combo["orders"]
    assert leg["option_type"] == "CALL"
    assert leg["strike_price"] == "180.00"
    assert leg["option_expire_date"] == "2026-06-19"
  end

  test "order_history/3 sends only account_id when no options given", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.query_string == "account_id=ACC-1"
      Req.Test.json(conn, [])
    end)

    assert {:ok, []} = ExWebull.Trading.order_history(client, "ACC-1")
  end

  test "open_orders/3 hits the open path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/open"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "page_size=50"
      Req.Test.json(conn, [])
    end)

    assert {:ok, []} = ExWebull.Trading.open_orders(client, "ACC-1", page_size: 50)
  end

  test "order_detail/3 sends account_id and client_order_id", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/detail"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "client_order_id=COID-1"
      Req.Test.json(conn, option_combo_order())
    end)

    assert {:ok, %{"combo_order_id" => "CMB-1"}} =
             ExWebull.Trading.order_detail(client, "ACC-1", "COID-1")
  end

  test "activities/3 hits the trading activity list", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trading/activity/list"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "activity_types=TRADE"
      assert q =~ "page_size=200"
      assert q =~ "last_activity_id=ACT-9"
      Req.Test.json(conn, [%{"id" => "ACT-1", "activity_type" => "TRADE"}])
    end)

    assert {:ok, [%{"activity_type" => "TRADE"}]} =
             ExWebull.Trading.activities(client, "ACC-1",
               activity_types: "TRADE",
               start_time: "2026-01-01T00:00:00.000Z",
               page_size: 200,
               last_activity_id: "ACT-9"
             )
  end

  test "open_orders/3 and activities/3 work without options", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trade/order/open"
      assert conn.query_string == "account_id=ACC-1"
      Req.Test.json(conn, [])
    end)

    assert {:ok, []} = ExWebull.Trading.open_orders(client, "ACC-1")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/trading/activity/list"
      assert conn.query_string == "account_id=ACC-1"
      Req.Test.json(conn, [])
    end)

    assert {:ok, []} = ExWebull.Trading.activities(client, "ACC-1")
  end
end
