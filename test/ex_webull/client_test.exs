defmodule ExWebull.ClientTest do
  use ExUnit.Case, async: true

  alias ExWebull.Client

  defp header(req, name), do: Req.Request.get_header(req, name)

  describe "new/3" do
    test "returns a Req.Request with the configured base url" do
      req = Client.new("ak", "sk")
      assert %Req.Request{} = req
      assert req.options.base_url == Client.base_url()
    end

    test "honors a :base_url override" do
      req = Client.new("ak", "sk", base_url: "https://example.test")
      assert req.options.base_url == "https://example.test"
    end

    test "sends x-version v2 by default and honours an override" do
      assert header(Client.new("ak", "sk"), "x-version") == ["v2"]
      assert header(Client.new("ak", "sk", api_version: "v1"), "x-version") == ["v1"]
    end

    test "sets x-access-token only when one is given" do
      assert header(Client.new("ak", "sk"), "x-access-token") == []
      assert header(Client.new("ak", "sk", access_token: "TKN"), "x-access-token") == ["TKN"]
    end
  end

  describe "new_market_data/3" do
    test "points at the market data host" do
      req = Client.new_market_data("ak", "sk")
      assert req.options.base_url == Client.market_data_base_url()
      assert req.options.base_url != Client.base_url()
    end

    test "an explicit base_url still wins" do
      req = Client.new_market_data("ak", "sk", base_url: "https://example.test")
      assert req.options.base_url == "https://example.test"
    end
  end

  describe "config getters" do
    test "base_url/0 returns the configured value" do
      assert Client.base_url() == "https://api.webull.com"
    end

    test "region/0 returns the configured region" do
      assert Client.region() == "US"
    end

    test "market_data_base_url/0 returns the configured value" do
      assert Client.market_data_base_url() == "https://broker-api.webull.com"
    end

    test "mqtt_endpoint/0 returns host/port tuple" do
      assert {"data-api.webull.com", 1883} = Client.mqtt_endpoint()
    end

    test "trade_events_endpoint/0 returns host/port tuple" do
      assert {"events-api.webull.com", 443} = Client.trade_events_endpoint()
    end
  end

  describe "handle_response/1" do
    defp resp(status, body \\ %{}), do: %Req.Response{status: status, body: body}

    test "2xx returns {:ok, body}" do
      assert {:ok, %{"a" => 1}} = Client.handle_response({:ok, resp(200, %{"a" => 1})})
      assert {:ok, _} = Client.handle_response({:ok, resp(299)})
    end

    test "401 -> :unauthorized" do
      assert {:error, {:unauthorized, _}} = Client.handle_response({:ok, resp(401)})
    end

    test "403 -> :forbidden" do
      assert {:error, {:forbidden, _}} = Client.handle_response({:ok, resp(403)})
    end

    test "404 -> :not_found" do
      assert {:error, {:not_found, _}} = Client.handle_response({:ok, resp(404)})
    end

    test "429 -> :rate_limited" do
      assert {:error, {:rate_limited, _}} = Client.handle_response({:ok, resp(429)})
    end

    test "other 4xx/5xx -> :api_error with status" do
      assert {:error, {:api_error, 400, _}} = Client.handle_response({:ok, resp(400)})
      assert {:error, {:api_error, 500, _}} = Client.handle_response({:ok, resp(500)})
    end

    test "transport error -> :connection_error" do
      assert {:error, {:connection_error, :timeout}} =
               Client.handle_response({:error, :timeout})
    end
  end
end
