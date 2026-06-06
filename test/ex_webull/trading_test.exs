defmodule ExWebull.TradingTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"trading_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "place_order/3 posts single order wrapped in new_orders list", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/account/orders/place"
      assert conn.query_string =~ "account_id=ACC-1"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert %{"new_orders" => [%{"symbol" => "AAPL"}]} = payload
      Req.Test.json(conn, %{"client_order_id" => "COID-1"})
    end)

    assert {:ok, %{"client_order_id" => "COID-1"}} =
             ExWebull.Trading.place_order(client, "ACC-1", %{symbol: "AAPL", quantity: "1"})
  end

  test "place_order/3 leaves a list as-is", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert %{"new_orders" => [%{"symbol" => "AAPL"}, %{"symbol" => "TSLA"}]} = payload
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.place_order(client, "ACC-1", [%{symbol: "AAPL"}, %{symbol: "TSLA"}])
  end

  test "cancel_order/3 posts client_order_id body", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/cancel"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"client_order_id" => "COID-1"} = Jason.decode!(body)
      Req.Test.json(conn, %{"ok" => true})
    end)

    assert {:ok, _} = ExWebull.Trading.cancel_order(client, "ACC-1", "COID-1")
  end

  test "order_history/3 forwards paging options", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/history"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "page_size=20"
      assert q =~ "start_date=2026-01-01"
      Req.Test.json(conn, %{"orders" => []})
    end)

    assert {:ok, _} =
             ExWebull.Trading.order_history(client, "ACC-1",
               page_size: 20,
               start_date: "2026-01-01"
             )
  end

  test "preview_order/3 and replace_order/3 target right endpoints", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/preview"
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.preview_order(client, "ACC-1", %{symbol: "AAPL"})

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/replace"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"modify_orders" => [_]} = Jason.decode!(body)
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.replace_order(client, "ACC-1", %{client_order_id: "X"})
  end

  test "place_option/3 and cancel_option/3 hit option paths", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/option/place"
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.place_option(client, "ACC-1", %{symbol: "AAPL"})

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/option/cancel"
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.cancel_option(client, "ACC-1", "COID-1")
  end

  test "order_detail/3 sends account_id and client_order_id params", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/openapi/account/orders/detail"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      assert q =~ "client_order_id=COID-1"
      Req.Test.json(conn, %{"client_order_id" => "COID-1"})
    end)

    assert {:ok, %{"client_order_id" => "COID-1"}} =
             ExWebull.Trading.order_detail(client, "ACC-1", "COID-1")
  end

  test "open_orders/2 hits legacy list-open and drops nils", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/orders/list-open"
      q = conn.query_string
      assert q =~ "account_id=ACC-1"
      refute q =~ "missing"
      Req.Test.json(conn, %{"orders" => []})
    end)

    assert {:ok, _} = ExWebull.Trading.open_orders(client, account_id: "ACC-1", missing: nil)
  end

  test "today_orders/2 hits legacy list-today", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/orders/list-today"
      Req.Test.json(conn, %{"orders" => []})
    end)

    assert {:ok, _} = ExWebull.Trading.today_orders(client, account_id: "ACC-1")
  end

  test "preview_option/3 targets option preview path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/account/orders/option/preview"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"new_orders" => [%{"symbol" => "AAPL"}]} = Jason.decode!(body)
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.preview_option(client, "ACC-1", %{symbol: "AAPL"})
  end

  test "replace_option/3 targets option replace path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/orders/option/replace"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{"modify_orders" => [%{"client_order_id" => "X"}]} = Jason.decode!(body)
      Req.Test.json(conn, %{})
    end)

    ExWebull.Trading.replace_option(client, "ACC-1", %{client_order_id: "X"})
  end
end
