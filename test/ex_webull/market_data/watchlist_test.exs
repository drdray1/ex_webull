defmodule ExWebull.MarketData.WatchlistTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.MarketData.Watchlist

  setup do
    stub = :"watchlist_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  defp body(conn) do
    {:ok, raw, conn} = Plug.Conn.read_body(conn)
    {Jason.decode!(raw), conn}
  end

  test "list/1 and instruments/2 are GETs", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/openapi/market-data/watchlist/list"
      Req.Test.json(conn, [])
    end)

    Watchlist.list(client)

    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/watchlist/instruments/list"
      assert conn.query_string == "watchlist_id=WL-1"
      Req.Test.json(conn, [])
    end)

    Watchlist.instruments(client, "WL-1")
  end

  test "create/3 omits an unset sort", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/watchlist/create"
      {payload, conn} = body(conn)
      assert payload["name"] == "Tech"
      refute Map.has_key?(payload, "sort")
      Req.Test.json(conn, %{"watchlist_id" => "WL-1"})
    end)

    assert {:ok, %{"watchlist_id" => "WL-1"}} = Watchlist.create(client, "Tech")
  end

  test "update/3 sends only what was passed", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/watchlist/update"
      {payload, conn} = body(conn)
      assert payload == %{"watchlist_id" => "WL-1", "name" => "Renamed"}
      Req.Test.json(conn, %{})
    end)

    Watchlist.update(client, "WL-1", name: "Renamed")
  end

  test "delete/2 posts the watchlist id", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/market-data/watchlist/delete"
      {payload, conn} = body(conn)
      assert payload == %{"watchlist_id" => "WL-1"}
      Req.Test.json(conn, %{})
    end)

    Watchlist.delete(client, "WL-1")
  end

  test "instrument mutations wrap a single instrument into a list", %{stub: stub, client: client} do
    for {fun, path} <- [
          {:add_instruments, "/openapi/market-data/watchlist/instruments/add"},
          {:remove_instruments, "/openapi/market-data/watchlist/instruments/remove"},
          {:update_instruments, "/openapi/market-data/watchlist/instruments/update"}
        ] do
      Req.Test.expect(stub, fn conn ->
        assert conn.request_path == path
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(raw)
        assert payload["watchlist_id"] == "WL-1"
        assert [%{"symbol" => "AAPL"}] = payload["instruments"]
        Req.Test.json(conn, %{})
      end)

      apply(Watchlist, fun, [client, "WL-1", %{symbol: "AAPL", category: "US_STOCK"}])
    end
  end

  test "update/3 with no fields sends only the watchlist id", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {payload, conn} = body(conn)
      assert payload == %{"watchlist_id" => "WL-1"}
      Req.Test.json(conn, %{})
    end)

    assert {:ok, _} = Watchlist.update(client, "WL-1")
  end
end
