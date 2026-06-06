defmodule ExWebull.CalendarTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"calendar_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "get/2 forwards params and drops nils", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/trade/calendar"
      q = conn.query_string
      assert q =~ "region=US"
      assert q =~ "start_date=2026-01-01"
      assert q =~ "end_date=2026-01-31"
      refute q =~ "exchange"
      Req.Test.json(conn, %{"trading_days" => []})
    end)

    assert {:ok, %{"trading_days" => []}} =
             ExWebull.Calendar.get(client,
               region: "US",
               start_date: "2026-01-01",
               end_date: "2026-01-31",
               exchange: nil
             )
  end

  test "get/1 works with no options", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/trade/calendar"
      Req.Test.json(conn, %{"trading_days" => []})
    end)

    assert {:ok, _} = ExWebull.Calendar.get(client)
  end
end
