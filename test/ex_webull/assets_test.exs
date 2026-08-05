defmodule ExWebull.AssetsTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"assets_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "positions/2 returns option legs", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/openapi/assets/positions"
      assert conn.query_string == "account_id=ACC-1"
      Req.Test.json(conn, [option_position()])
    end)

    assert {:ok, [position]} = ExWebull.Assets.positions(client, "ACC-1")
    assert position["option_strategy"] == "SINGLE"
    assert [%{"option_type" => "CALL", "option_exercise_price" => "180.00"}] = position["legs"]
  end

  test "balance/2 hits the assets balance path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/assets/balance"
      assert conn.query_string == "account_id=ACC-1"
      Req.Test.json(conn, balance_response())
    end)

    assert {:ok, %{"account_id" => "ACC-1"}} = ExWebull.Assets.balance(client, "ACC-1")
  end
end
