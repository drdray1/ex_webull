defmodule ExWebull do
  @moduledoc """
  Elixir client for the [Webull OpenAPI](https://developer.webull.com/api-doc/).

  Covers the HTTP Trading and Market-Data REST endpoints, the gRPC
  market-data and trade-events streams, and the MQTT market-push channel.

  ## Quick start — HTTP trading

      client = ExWebull.Client.new("app_key", "app_secret")

      {:ok, accounts} = ExWebull.Account.list(client)
      {:ok, balance} = ExWebull.Account.balance(client, "ACC-1")

      {:ok, resp} =
        ExWebull.Trading.place_order(client, "ACC-1", %{
          symbol: "AAPL",
          quantity: "1",
          side: "BUY",
          tif: "DAY",
          order_type: "MKT"
        })

  ## Streaming market data (MQTT)

      {:ok, grpc} =
        ExWebull.Grpc.Client.start_link(app_key: "ak", app_secret: "sk")

      {:ok, %{token: token}} = ExWebull.Market.Token.get(grpc)

      {:ok, mqtt} =
        ExWebull.Mqtt.Connection.start_link(
          app_key: "ak",
          token: token,
          subscribers: [self()]
        )

      ExWebull.Market.Subscribe.subscribe(grpc, token, ["AAPL"], "US_STOCK", ["SNAPSHOT"])
      ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "913256135-1-1000")

      receive do
        {:webull_event, topic, {:snapshot, snap}} -> IO.inspect(snap)
      end

  ## Streaming trade events (gRPC)

      {:ok, ev} =
        ExWebull.TradeEvents.Connection.start_link(
          app_key: "ak",
          app_secret: "sk",
          accounts: ["ACC-1"],
          subscribers: [self()]
        )

      receive do
        {:webull_trade_event, %ExWebull.TradeEvents.Event{} = e} -> IO.inspect(e)
      end

  ## Configuration

  Override endpoints via `config/config.exs`:

      config :ex_webull, :config,
        base_url: "https://api.webull.com",
        mqtt_host: "usquotes-api.webullfintech.com",
        mqtt_port: 8883,
        quotes_host: "api.webull.com",
        quotes_port: 443,
        trade_events_host: "events-api.webull.com",
        trade_events_port: 443,
        region: "US"

  See `ExWebull.Client`, `ExWebull.Auth`, `ExWebull.Grpc.Client`,
  `ExWebull.Mqtt.Connection`, and `ExWebull.TradeEvents.Connection` for
  details.
  """

  defdelegate new(app_key, app_secret, opts \\ []), to: ExWebull.Client, as: :new
end
