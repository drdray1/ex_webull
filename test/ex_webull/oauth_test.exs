defmodule ExWebull.OAuthTest do
  use ExUnit.Case, async: true

  import ExWebull.Fixtures

  setup do
    stub = :"oauth_stub_#{System.unique_integer([:positive])}"
    {:ok, stub: stub, client: test_client(stub)}
  end

  test "authorize_url/2 builds the login URL" do
    url =
      ExWebull.OAuth.authorize_url("CID",
        scope: "user,trade",
        state: "xyz",
        redirect_uri: "https://example.com/cb",
        base_url: "https://api.webull.com"
      )

    assert %URI{host: "api.webull.com", path: "/oauth2/authenticate/login"} = URI.parse(url)
    q = url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    assert q["response_type"] == "code"
    assert q["client_id"] == "CID"
    assert q["scope"] == "user,trade"
    assert q["state"] == "xyz"
    assert q["redirect_uri"] == "https://example.com/cb"
  end

  test "authorize_url/2 requires scope, state and redirect_uri" do
    assert_raise KeyError, fn -> ExWebull.OAuth.authorize_url("CID", state: "x") end
  end

  test "create_token/4 posts an authorization_code grant", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      assert conn.request_path == "/openapi/oauth2/token"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["grant_type"] == "authorization_code"
      assert payload["code"] == "CODE"
      refute Map.has_key?(payload, "refresh_token")
      Req.Test.json(conn, %{"access_token" => "AT"})
    end)

    assert {:ok, %{"access_token" => "AT"}} =
             ExWebull.OAuth.create_token(client, "CID", "SECRET", "CODE")
  end

  test "refresh_token/4 posts a refresh_token grant", %{stub: stub, client: client} do
    Req.Test.expect(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["grant_type"] == "refresh_token"
      assert payload["refresh_token"] == "RT"
      refute Map.has_key?(payload, "code")
      Req.Test.json(conn, %{"access_token" => "AT2"})
    end)

    assert {:ok, %{"access_token" => "AT2"}} =
             ExWebull.OAuth.refresh_token(client, "CID", "SECRET", "RT")
  end
end
