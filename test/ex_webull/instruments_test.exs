defmodule ExWebull.InstrumentsTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"instruments_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "list/3 forwards symbols and category", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/instrument/list"
      q = conn.query_string
      assert q =~ "symbols=AAPL%2CTSLA" or q =~ "symbols=AAPL,TSLA"
      assert q =~ "category=US_STOCK"
      Req.Test.json(conn, %{"data" => []})
    end)

    assert {:ok, %{"data" => []}} =
             ExWebull.Instruments.list(client, "AAPL,TSLA", "US_STOCK")
  end

  test "corp_action/2 forwards options and drops nils", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/instrument/corp-action"
      q = conn.query_string
      assert q =~ "instrument_id=123"
      refute q =~ "missing"
      Req.Test.json(conn, %{"data" => []})
    end)

    assert {:ok, _} =
             ExWebull.Instruments.corp_action(client, instrument_id: "123", missing: nil)
  end

  test "trade_instrument/2 hits the legacy path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/instrument"
      assert conn.query_string =~ "symbol=AAPL"
      Req.Test.json(conn, %{"data" => %{}})
    end)

    assert {:ok, _} = ExWebull.Instruments.trade_instrument(client, symbol: "AAPL")
  end

  test "trade_security/2 hits the legacy path", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/security"
      Req.Test.json(conn, %{"data" => %{}})
    end)

    assert {:ok, _} = ExWebull.Instruments.trade_security(client, symbol: "AAPL")
  end

  test "tradable/2 lists tradable instruments", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/instrument/tradable/list"
      Req.Test.json(conn, %{"data" => []})
    end)

    assert {:ok, _} = ExWebull.Instruments.tradable(client)
  end

  test "404 returns :not_found tag", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn -> Plug.Conn.send_resp(conn, 404, "missing") end)
    assert {:error, {:not_found, _}} = ExWebull.Instruments.list(client, "AAPL", "US_STOCK")
  end
end
