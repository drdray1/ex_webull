defmodule ExWebull.MarketData.AssetClassesTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.MarketData.{Crypto, Event, Futures, Option}

  setup do
    stub = :"md_assets_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp query(conn), do: URI.decode_query(conn.query_string)

  describe "options" do
    test "snapshot/3 joins OCC symbols", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/option/snapshot"
        q = query(conn)
        assert q["symbols"] == "AAPL260619C00180000,AAPL260619P00170000"
        assert q["category"] == "US_OPTION"
        Req.Test.json(conn, [%{"symbol" => "AAPL260619C00180000", "delta" => "0.51"}])
      end)

      assert {:ok, [%{"delta" => "0.51"}]} =
               Option.snapshot(client, ["AAPL260619C00180000", "AAPL260619P00170000"])
    end

    test "tick/4 sends count", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/option/tick"
        q = query(conn)
        assert q["symbol"] == "AAPL260619C00180000"
        assert q["count"] == "500"
        Req.Test.json(conn, %{"result" => []})
      end)

      assert {:ok, %{"result" => []}} = Option.tick(client, "AAPL260619C00180000", 500)
    end

    test "bars/4 drops nil options", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/option/bars"
        q = query(conn)
        assert q["timespan"] == "D"
        assert q["count"] == "30"
        refute Map.has_key?(q, "real_time_required")
        Req.Test.json(conn, %{"result" => []})
      end)

      Option.bars(client, "AAPL260619C00180000", "D", count: 30, real_time_required: nil)
    end
  end

  describe "futures" do
    test "snapshot/3 and depth/4 default US_FUTURES", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/futures/snapshot"
        assert query(conn)["category"] == "US_FUTURES"
        assert query(conn)["symbols"] == "SILZ5,6BM6"
        Req.Test.json(conn, [])
      end)

      Futures.snapshot(client, ["SILZ5", "6BM6"])

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/futures/depth"
        assert query(conn)["depth"] == "5"
        Req.Test.json(conn, %{})
      end)

      Futures.depth(client, "SILZ5", 5)
    end

    test "tick/4, bars/5 and footprint/4 send required params", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/futures/tick"
        assert query(conn)["count"] == "200"
        Req.Test.json(conn, %{})
      end)

      Futures.tick(client, "SILZ5", 200)

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/futures/bars"
        q = query(conn)
        assert q["timespan"] == "M5"
        assert q["count"] == "100"
        Req.Test.json(conn, %{})
      end)

      Futures.bars(client, "SILZ5", "M5", 100)

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/futures/footprint"
        assert query(conn)["timespan"] == "S15"
        Req.Test.json(conn, %{})
      end)

      Futures.footprint(client, "SILZ5", "S15")
    end
  end

  describe "crypto" do
    test "snapshot/3 and bars/4 default US_CRYPTO", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/crypto/snapshot"
        assert query(conn)["category"] == "US_CRYPTO"
        Req.Test.json(conn, [])
      end)

      Crypto.snapshot(client, "BTCUSD")

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/crypto/bars"
        q = query(conn)
        assert q["timespan"] == "M1"
        assert q["real_time_required"] == "false"
        Req.Test.json(conn, %{})
      end)

      Crypto.bars(client, "BTCUSD", "M1", real_time_required: "false")
    end
  end

  describe "event contracts" do
    test "snapshot, depth, tick and bars default US_EVENT", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/event/snapshot"
        assert query(conn)["category"] == "US_EVENT"
        Req.Test.json(conn, [])
      end)

      Event.snapshot(client, "EVT-1")

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/event/depth"
        assert query(conn)["depth"] == "20"
        Req.Test.json(conn, %{})
      end)

      Event.depth(client, "EVT-1", depth: 20)

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/event/tick"
        assert query(conn)["count"] == "50"
        Req.Test.json(conn, %{})
      end)

      Event.tick(client, "EVT-1", count: 50)

      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == "/openapi/market-data/event/bars"
        assert query(conn)["timespan"] == "M15"
        Req.Test.json(conn, %{})
      end)

      Event.bars(client, "EVT-1", "M15")
    end
  end

  test "asset-class defaults apply when opts are omitted", %{stub: stub, client: client} do
    calls = [
      {"/openapi/market-data/option/bars", "US_OPTION",
       fn -> Option.bars(client, "AAPL260619C00180000", "D") end},
      {"/openapi/market-data/crypto/bars", "US_CRYPTO",
       fn -> Crypto.bars(client, "BTCUSD", "D") end},
      {"/openapi/market-data/event/depth", "US_EVENT", fn -> Event.depth(client, "EVT-1") end},
      {"/openapi/market-data/event/tick", "US_EVENT", fn -> Event.tick(client, "EVT-1") end}
    ]

    for {path, category, call} <- calls do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        assert URI.decode_query(conn.query_string)["category"] == category
        Req.Test.json(conn, %{})
      end)

      assert {:ok, _} = call.()
    end
  end
end
