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
      assert Plug.Conn.get_req_header(conn, "x-version") == ["v2"]
      Req.Test.json(conn, account_list_response())
    end)

    assert {:ok, %{"accounts" => [_ | _]}} = ExWebull.Account.list(client)
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
