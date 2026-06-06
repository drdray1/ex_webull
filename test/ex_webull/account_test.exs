defmodule ExWebull.AccountTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"account_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "list/1 returns account list", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/openapi/account/list"
      Req.Test.json(conn, account_list_response())
    end)

    assert {:ok, %{"accounts" => [_ | _]}} = ExWebull.Account.list(client)
  end

  test "balance/2 sends account_id query param", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/balance"
      assert conn.query_string =~ "account_id=ACC-1"
      Req.Test.json(conn, balance_response())
    end)

    assert {:ok, %{"account_id" => "ACC-1"}} = ExWebull.Account.balance(client, "ACC-1")
  end

  test "positions/2 sends account_id query param", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/positions"
      assert conn.query_string =~ "account_id=ACC-1"
      Req.Test.json(conn, %{"positions" => []})
    end)

    assert {:ok, %{"positions" => []}} = ExWebull.Account.positions(client, "ACC-1")
  end

  test "position_details/3 includes size and last_instrument_id", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/account/position/details"
      assert conn.query_string =~ "account_id=ACC-1"
      assert conn.query_string =~ "size=50"
      assert conn.query_string =~ "last_instrument_id=XYZ"
      Req.Test.json(conn, %{"positions" => []})
    end)

    assert {:ok, _} =
             ExWebull.Account.position_details(client, "ACC-1",
               size: 50,
               last_instrument_id: "XYZ"
             )
  end

  test "profile/1 hits the legacy profile path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/account/profile"
      Req.Test.json(conn, %{"user_id" => "U-1"})
    end)

    assert {:ok, %{"user_id" => "U-1"}} = ExWebull.Account.profile(client)
  end

  test "401 returns :unauthorized tag", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn -> Plug.Conn.send_resp(conn, 401, "unauthorized") end)
    assert {:error, {:unauthorized, _}} = ExWebull.Account.list(client)
  end

  test "500 returns :api_error", %{stub: stub, client: client} do
    Req.Test.stub(stub, fn conn -> Plug.Conn.send_resp(conn, 500, "boom") end)
    assert {:error, {:api_error, 500, _}} = ExWebull.Account.list(client)
  end
end
