defmodule ExWebull.RequestTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures
  alias ExWebull.Request

  describe "symbols/1" do
    test "joins a list and passes a single symbol through" do
      assert Request.symbols(["AAPL", "TSLA"]) == "AAPL,TSLA"
      assert Request.symbols("AAPL") == "AAPL"
      assert Request.symbols([]) == ""
    end
  end

  describe "compact/1" do
    test "drops nil values from keyword lists and maps" do
      assert Request.compact(a: 1, b: nil, c: "x") == [a: 1, c: "x"]
      assert Request.compact(%{a: 1, b: nil}) == [a: 1]
    end

    test "keeps falsey-but-present values" do
      assert Request.compact(a: false, b: 0, c: "") == [a: false, b: 0, c: ""]
    end
  end

  describe "get/3 and post/3" do
    setup do
      stub = :"request_stub_#{System.unique_integer([:positive])}"
      {:ok, stub: stub, client: test_client(stub)}
    end

    test "get/3 drops nil params", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/some/path"
        assert conn.query_string == "a=1"
        Req.Test.json(conn, %{"ok" => true})
      end)

      assert {:ok, %{"ok" => true}} = Request.get(client, "/some/path", a: 1, b: nil)
    end

    test "get/3 sends no query string when everything is nil", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.query_string == ""
        Req.Test.json(conn, %{})
      end)

      Request.get(client, "/some/path", a: nil)
    end

    test "post/3 drops nil members and sends JSON", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.method == "POST"
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"a" => 1}
        Req.Test.json(conn, %{})
      end)

      Request.post(client, "/some/path", %{a: 1, b: nil})
    end

    test "post/3 defaults to an empty body", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{}
        Req.Test.json(conn, %{})
      end)

      Request.post(client, "/some/path")
    end

    test "errors propagate through handle_response/1", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn -> Plug.Conn.send_resp(conn, 404, "nope") end)
      assert {:error, {:not_found, _}} = Request.get(client, "/some/path")
    end
  end
end
