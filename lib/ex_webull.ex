defmodule ExWebull do
  @moduledoc """
  Elixir client for the [Webull OpenAPI](https://developer.webull.com/apis/docs/).

  Covers the HTTP Trading, Market Data, Instrument, and Fundamentals
  endpoints, the MQTT market-data stream, and the gRPC trade-events
  stream.

  ## Two clients

  Trading and market data live on different hosts:

      trade = ExWebull.Client.new("app_key", "app_secret")
      md    = ExWebull.Client.new_market_data("app_key", "app_secret")

  With Two-Factor Authentication enabled, create and verify an access
  token first — see `ExWebull.Token`.

  ## Modules

  | Area | Module |
  |---|---|
  | Accounts | `ExWebull.Account`, `ExWebull.Assets` |
  | Orders and activity | `ExWebull.Trading` |
  | Instrument reference data | `ExWebull.Instruments` |
  | Market data | `ExWebull.MarketData.Stock`, `.Option`, `.Futures`, `.Crypto`, `.Event` |
  | Ranked lists and watchlists | `ExWebull.MarketData.Screener`, `.Watchlist` |
  | Streaming subscriptions | `ExWebull.MarketData.Streaming`, `ExWebull.Mqtt.Connection` |
  | Fundamentals | `ExWebull.Fundamentals.Stock`, `.Financial`, `.Fund` |
  | News | `ExWebull.News` |
  | Auth | `ExWebull.Token`, `ExWebull.OAuth`, `ExWebull.Auth` |
  | Trade events | `ExWebull.TradeEvents.Connection` |

  ## Quick start — trading

      {:ok, accounts} = ExWebull.Account.list(trade)
      {:ok, balance} = ExWebull.Assets.balance(trade, "ACC-1")

      {:ok, resp} =
        ExWebull.Trading.place_order(trade, "ACC-1", %{
          client_order_id: "unique-id",
          combo_type: "NORMAL",
          instrument_type: "EQUITY",
          market: "US",
          symbol: "AAPL",
          side: "BUY",
          order_type: "MARKET",
          quantity: "1",
          entrust_type: "QTY",
          time_in_force: "DAY"
        })

  ## Streaming market data (MQTT)

      {:ok, mqtt} =
        ExWebull.Mqtt.Connection.start_link(
          app_key: "ak",
          session_id: "my-session",
          subscribers: [self()]
        )

      ExWebull.MarketData.Streaming.subscribe(md, "my-session", ["AAPL"],
        sub_types: ["SNAPSHOT"]
      )

      ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "snapshot")

      receive do
        {:webull_event, "snapshot", {:snapshot, snap}} -> IO.inspect(snap)
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
        market_data_base_url: "https://broker-api.webull.com",
        mqtt_host: "data-api.webull.com",
        mqtt_port: 1883,
        trade_events_host: "events-api.webull.com",
        trade_events_port: 443,
        region: "US"
  """

  defdelegate new(app_key, app_secret, opts \\ []), to: ExWebull.Client, as: :new

  defdelegate new_market_data(app_key, app_secret, opts \\ []),
    to: ExWebull.Client,
    as: :new_market_data
end
