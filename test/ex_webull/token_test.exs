defmodule ExWebull.TokenTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"token_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "create/1 posts to the create path with an empty body", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/openapi/auth/token/create"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{}
      Req.Test.json(conn, %{"token" => "TKN", "status" => "PENDING", "expires" => 1})
    end)

    assert {:ok, %{"token" => "TKN", "status" => "PENDING"}} = ExWebull.Token.create(client)
  end

  test "check/2 posts the token", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/auth/token/check"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"token" => "TKN"}
      Req.Test.json(conn, %{"token" => "TKN", "status" => "NORMAL"})
    end)

    assert {:ok, %{"status" => "NORMAL"}} = ExWebull.Token.check(client, "TKN")
  end

  test "an access token is sent as x-access-token on other calls" do
    stub = :"token_hdr_stub_#{System.unique_integer([:positive])}"
    client = test_client(stub, access_token: "TKN")

    Req.Test.expect(stub, fn conn ->
      assert Plug.Conn.get_req_header(conn, "x-access-token") == ["TKN"]
      Req.Test.json(conn, %{})
    end)

    ExWebull.Account.list(client)
  end

  test "no access-token header when none was configured" do
    stub = :"token_nohdr_stub_#{System.unique_integer([:positive])}"
    client = test_client(stub)

    Req.Test.expect(stub, fn conn ->
      assert Plug.Conn.get_req_header(conn, "x-access-token") == []
      Req.Test.json(conn, %{})
    end)

    ExWebull.Account.list(client)
  end
end
