defmodule ExWebull.ClientTest do
  use ExUnit.Case, async: true

  alias ExWebull.Client

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
  end

  describe "config getters" do
    test "base_url/0 returns the configured value" do
      assert Client.base_url() == "https://api.webull.com"
    end

    test "region/0 returns the configured region" do
      assert Client.region() == "US"
    end

    test "mqtt_endpoint/0 returns host/port tuple" do
      assert {"usquotes-api.webullfintech.com", 8883} = Client.mqtt_endpoint()
    end

    test "quotes_grpc_endpoint/0 returns host/port tuple" do
      assert {"api.webull.com", 443} = Client.quotes_grpc_endpoint()
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
