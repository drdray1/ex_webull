defmodule ExWebull.NewsTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"news_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "summary/3 wraps a single category group and omits an unset lang", %{
    stub: stub,
    client: client
  } do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/news/summary"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert [%{"category" => "US_STOCK", "symbols" => ["AAPL"]}] = payload["category_symbols"]
      refute Map.has_key?(payload, "lang")
      Req.Test.json(conn, %{"summaries" => []})
    end)

    assert {:ok, %{"summaries" => []}} =
             ExWebull.News.summary(client, %{category: "US_STOCK", symbols: ["AAPL"]})
  end

  test "summary/3 forwards lang", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body)["lang"] == "en"
      Req.Test.json(conn, %{})
    end)

    ExWebull.News.summary(client, [%{category: "US_STOCK", symbols: ["AAPL"]}], lang: "en")
  end
end
