defmodule ExWebull.InstrumentsTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"instruments_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp query(conn), do: URI.decode_query(conn.query_string)

  test "stocks/2 defaults category and joins a symbol list", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/stock/list"
      q = query(conn)
      assert q["category"] == "US_STOCK"
      assert q["symbols"] == "AAPL,TSLA"
      assert q["status"] == "OC"
      refute Map.has_key?(q, "page_size")
      Req.Test.json(conn, [])
    end)

    assert {:ok, []} =
             ExWebull.Instruments.stocks(client, symbols: ["AAPL", "TSLA"], status: "OC")
  end

  test "options/2 forwards contract filters", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/option/contracts"
      q = query(conn)
      assert q["category"] == "US_OPTION"
      assert q["underlying_symbols"] == "AAPL"
      assert q["option_type"] == "CALL"
      assert q["end_date"] == "2026-06-19"
      assert q["strike_price_gte"] == "150"
      assert q["page_size"] == "1000"

      Req.Test.json(conn, [
        %{
          "instrument_id" => "INST-1",
          "symbol" => "AAPL260619C00180000",
          "underlying_symbol" => "AAPL",
          "option_type" => "CALL",
          "strike_price" => "180.00",
          "expiration_date" => "2026-06-19",
          "multiplier" => "100"
        }
      ])
    end)

    assert {:ok, [%{"symbol" => "AAPL260619C00180000"}]} =
             ExWebull.Instruments.options(client,
               underlying_symbols: "AAPL",
               option_type: "CALL",
               end_date: "2026-06-19",
               strike_price_gte: "150",
               page_size: 1000
             )
  end

  test "options/2 accepts a single OCC symbol", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert query(conn)["option_symbol"] == "AAPL260619C00180000"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.options(client, option_symbol: "AAPL260619C00180000")
  end

  test "futures lookups default the category", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/futures/list"
      assert query(conn)["category"] == "US_FUTURES"
      assert query(conn)["symbols"] == "SILZ5,6BM6"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.futures(client, symbols: ["SILZ5", "6BM6"])

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/futures/products"
      assert query(conn)["product_class_id"] == "7"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.futures_products(client, product_class_id: 7)

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/futures/product-classes"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.futures_product_classes(client)
  end

  test "crypto/2 defaults US_CRYPTO", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/crypto/list"
      assert query(conn)["category"] == "US_CRYPTO"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.crypto(client)
  end

  test "event contract lookups hit their paths", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/categories"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.event_categories(client)

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/series/list"
      assert query(conn)["category"] == "ECONOMICS"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.event_series(client, category: "ECONOMICS")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/events"
      assert query(conn)["series_symbol"] == "JOBS"
      assert query(conn)["status"] == "ACTIVE"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.event_events(client, "JOBS", status: "ACTIVE")

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/market/list"
      assert query(conn)["series_symbol"] == "JOBS"
      Req.Test.json(conn, [])
    end)

    ExWebull.Instruments.event_markets(client, "JOBS")
  end

  test "company and analyst lookups default US_STOCK", %{stub: stub, client: client} do
    for {fun, path} <- [
          {:company_profile, "/openapi/instrument/company/profile"},
          {:analyst_rating, "/openapi/instrument/analyst/rating"},
          {:analyst_target_price, "/openapi/instrument/analyst/target-price"}
        ] do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        q = URI.decode_query(conn.query_string)
        assert q["symbol"] == "AAPL"
        assert q["category"] == "US_STOCK"
        Req.Test.json(conn, %{})
      end)

      apply(ExWebull.Instruments, fun, [client, "AAPL"])
    end
  end

  test "lookups apply their category defaults when opts are omitted", %{
    stub: stub,
    client: client
  } do
    calls = [
      {"/openapi/instrument/stock/list", "US_STOCK",
       fn -> ExWebull.Instruments.stocks(client) end},
      {"/openapi/instrument/option/contracts", "US_OPTION",
       fn -> ExWebull.Instruments.options(client) end},
      {"/openapi/instrument/futures/list", "US_FUTURES",
       fn -> ExWebull.Instruments.futures(client) end},
      {"/openapi/instrument/futures/products", "US_FUTURES",
       fn -> ExWebull.Instruments.futures_products(client) end}
    ]

    for {path, category, call} <- calls do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        assert URI.decode_query(conn.query_string)["category"] == category
        Req.Test.json(conn, [])
      end)

      assert {:ok, _} = call.()
    end
  end

  test "event lookups omit absent filters entirely", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/series/list"
      assert conn.query_string == ""
      Req.Test.json(conn, [])
    end)

    assert {:ok, _} = ExWebull.Instruments.event_series(client)

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/instrument/event/events"
      assert conn.query_string == "series_symbol=JOBS"
      Req.Test.json(conn, [])
    end)

    assert {:ok, _} = ExWebull.Instruments.event_events(client, "JOBS")
  end
end
