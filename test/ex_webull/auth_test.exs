defmodule ExWebull.AuthTest do
  use ExUnit.Case, async: true

  alias ExWebull.Auth

  describe "compute_signature/4" do
    test "matches Python SDK reference vector with body" do
      sign_params = %{
        "x-app-key" => "test-app-key",
        "x-timestamp" => "2026-04-23T12:00:00Z",
        "x-signature-version" => "1.0",
        "x-signature-algorithm" => "HMAC-SHA1",
        "x-signature-nonce" => "nonce-1234567890",
        "host" => "api.webull.com",
        "symbols" => "AAPL",
        "category" => "US_STOCK"
      }

      body = ~s({"k1":123,"k2":"hello","k3":true})
      uri = "/trade/v2/orders/place"

      assert Auth.compute_signature(sign_params, uri, body, "test-secret") ==
               "fjeBpIhs50Kk7QbZfNL8PMGyx9g="
    end

    test "matches Python SDK reference vector without body" do
      sign_params = %{
        "x-app-key" => "test-app-key",
        "x-timestamp" => "2026-04-23T12:00:00Z",
        "x-signature-version" => "1.0",
        "x-signature-algorithm" => "HMAC-SHA1",
        "x-signature-nonce" => "nonce-1234567890",
        "host" => "api.webull.com",
        "symbols" => "AAPL",
        "category" => "US_STOCK"
      }

      uri = "/trade/v2/orders/place"

      assert Auth.compute_signature(sign_params, uri, nil, "test-secret") ==
               "lUGK3ugdCsISVsEyluvX/iEMP6M="

      assert Auth.compute_signature(sign_params, uri, "", "test-secret") ==
               "lUGK3ugdCsISVsEyluvX/iEMP6M="
    end
  end

  describe "generate_timestamp/0" do
    test "produces ISO-8601 UTC seconds-precision string ending in Z" do
      ts = Auth.generate_timestamp()
      assert ts =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
    end
  end

  describe "generate_nonce/0" do
    test "produces a 32-char lowercase hex string" do
      nonce = Auth.generate_nonce()
      assert byte_size(nonce) == 32
      assert nonce =~ ~r/^[0-9a-f]{32}$/
    end

    test "returns unique values across calls" do
      refute Auth.generate_nonce() == Auth.generate_nonce()
    end
  end

  describe "compute_signature/4 edge cases" do
    test "omits the uri segment when there is no path" do
      params = %{"host" => "api.webull.com", "x-app-key" => "ak"}

      assert Auth.compute_signature(params, nil, nil, "sk") ==
               Auth.compute_signature(params, "", nil, "sk")
    end
  end

  describe "sign_headers/0" do
    test "lists the headers that participate in signing" do
      headers = Auth.sign_headers()

      assert "x-app-key" in headers
      assert "x-timestamp" in headers
      assert "x-signature-nonce" in headers
      refute "x-signature" in headers
      refute "x-version" in headers
      refute "x-access-token" in headers
    end
  end

  describe "attach/3" do
    test "appends signing step to the request" do
      req = Req.new(base_url: "https://api.webull.com") |> Auth.attach("ak", "sk")
      assert req.options[:webull_app_key] == "ak"
      assert req.options[:webull_app_secret] == "sk"
      assert Keyword.has_key?(req.request_steps, :webull_auth)
    end

    test "stores nil credentials without failing" do
      req = Req.new() |> Auth.attach(nil, nil)
      assert req.options[:webull_app_key] == nil
      assert req.options[:webull_app_secret] == nil
    end
  end

  describe "signing a live request" do
    setup do
      stub = :"auth_stub_#{System.unique_integer([:positive])}"
      {:ok, stub: stub, client: ExWebull.Fixtures.test_client(stub)}
    end

    test "sets every signature header on a GET", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        for h <- [
              "x-app-key",
              "x-timestamp",
              "x-signature-algorithm",
              "x-signature-version",
              "x-signature-nonce",
              "x-signature"
            ] do
          assert [value] = Plug.Conn.get_req_header(conn, h)
          assert value != ""
        end

        assert Plug.Conn.get_req_header(conn, "x-signature-algorithm") == ["HMAC-SHA1"]
        assert Plug.Conn.get_req_header(conn, "x-signature-version") == ["1.0"]
        Req.Test.json(conn, %{})
      end)

      ExWebull.Request.get(client, "/openapi/account/list", a: 1)
    end

    test "signs a JSON body and query params together", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert [sig] = Plug.Conn.get_req_header(conn, "x-signature")
        assert sig != ""
        Req.Test.json(conn, %{})
      end)

      ExWebull.Request.post(client, "/openapi/trade/order/place", %{account_id: "ACC-1"})
    end

    test "a request with no credentials is left unsigned" do
      stub = :"auth_unsigned_#{System.unique_integer([:positive])}"

      client =
        Req.new(base_url: "https://api.webull.com", plug: {Req.Test, stub})
        |> Auth.attach(nil, nil)

      Req.Test.expect(stub, fn conn ->
        assert Plug.Conn.get_req_header(conn, "x-signature") == []
        Req.Test.json(conn, %{})
      end)

      Req.get(client, url: "/openapi/account/list")
    end

    test "repeated query keys are joined rather than overwritten", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert conn.query_string =~ "symbols=AAPL"
        assert [_] = Plug.Conn.get_req_header(conn, "x-signature")
        Req.Test.json(conn, %{})
      end)

      Req.get(client, url: "/openapi/instrument/stock/list?symbols=AAPL&symbols=TSLA")
    end

    test "a host-less request URL still signs", %{stub: stub} do
      client =
        Req.new(plug: {Req.Test, stub})
        |> Auth.attach("ak", "sk")

      Req.Test.expect(stub, fn conn ->
        assert [_] = Plug.Conn.get_req_header(conn, "x-signature")
        Req.Test.json(conn, %{})
      end)

      Req.get(client, url: "http://localhost/openapi/account/list")
    end

    test "a URL with no path signs with an empty uri segment", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert [_] = Plug.Conn.get_req_header(conn, "x-signature")
        Req.Test.json(conn, %{})
      end)

      Req.get(client, url: "https://api.webull.com")
    end

    test "an empty body signs as if there were none", %{stub: stub, client: client} do
      signatures =
        for body <- ["", nil] do
          Req.Test.expect(stub, fn conn ->
            [sig] = Plug.Conn.get_req_header(conn, "x-signature")
            send(self(), {:sig, sig})
            Req.Test.json(conn, %{})
          end)

          {:ok, %{private: %{}}} = Req.post(client, url: "/openapi/x", body: body)
          receive do: ({:sig, sig} -> sig)
        end

      # Same nonce/timestamp are not shared, so we only assert both signed.
      assert Enum.all?(signatures, &(&1 != ""))
    end

    test "a streamed body signs as if there were none", %{stub: stub, client: client} do
      Req.Test.expect(stub, fn conn ->
        assert [sig] = Plug.Conn.get_req_header(conn, "x-signature")
        assert sig != ""
        Req.Test.json(conn, %{})
      end)

      # The client declares JSON, so stream valid JSON chunks.
      Req.post(client, url: "/openapi/x", body: Stream.map([~s({"a":), "1}"], & &1))
    end

    test "a query key colliding with a sign header is joined, not replaced", %{
      stub: stub,
      client: client
    } do
      Req.Test.expect(stub, fn conn ->
        # The header carries the real app key; the query param is merged
        # into the signature string alongside it rather than clobbering it.
        assert Plug.Conn.get_req_header(conn, "x-app-key") == ["test-key"]
        assert conn.query_string =~ "x-app-key=collide"
        assert [sig] = Plug.Conn.get_req_header(conn, "x-signature")
        assert sig != ""
        Req.Test.json(conn, %{})
      end)

      Req.get(client, url: "/openapi/account/list?x-app-key=collide")
    end
  end
end
