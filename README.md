# ExWebull

An Elixir client for the [Webull OpenAPI](https://developer.webull.com/api-doc/).

Feature parity with the
[official Python SDK](https://github.com/webull-inc/openapi-python-sdk):

- **HTTP REST** — Trading (v2 accounts, orders, options), Instruments,
  Trading Calendar, Market Data (snapshots, bars).
- **gRPC market data** — Candlesticks, Snapshot, Order Book, Tick-by-Tick,
  token, subscribe/unsubscribe.
- **MQTT market push** — streaming snapshots, quotes, and ticks over
  MQTT v3.1.1 with TLS, decoded from protobuf to typed Elixir structs.
- **gRPC trade events** — server-streaming order status updates with
  JSON-decoded payloads.

All signed requests use Webull's HMAC-SHA1 scheme, verified against the
Python SDK's reference vectors.

## Installation

```elixir
def deps do
  [
    {:ex_webull, "~> 0.1.0"}
  ]
end
```

## Quick start

### Trading HTTP

```elixir
client = ExWebull.Client.new("app_key", "app_secret")

{:ok, accounts} = ExWebull.Account.list(client)
{:ok, balance}  = ExWebull.Account.balance(client, "ACC-1")

{:ok, resp} =
  ExWebull.Trading.place_order(client, "ACC-1", %{
    symbol: "AAPL", quantity: "1", side: "BUY",
    tif: "DAY", order_type: "MKT"
  })

ExWebull.Trading.cancel_order(client, "ACC-1", resp["client_order_id"])
```

### Market data streaming (MQTT + gRPC)

```elixir
{:ok, grpc} =
  ExWebull.Grpc.Client.start_link(app_key: "ak", app_secret: "sk")

{:ok, %{token: token}} = ExWebull.Market.Token.get(grpc)

{:ok, mqtt} =
  ExWebull.Mqtt.Connection.start_link(
    app_key: "ak", token: token, subscribers: [self()]
  )

ExWebull.Market.Subscribe.subscribe(grpc, token, ["AAPL"], "US_STOCK", ["SNAPSHOT"])
ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "913256135-1-1000")

receive do
  {:webull_event, topic, {:snapshot, snap}} -> IO.inspect(snap)
end
```

### Trade events streaming (gRPC)

```elixir
{:ok, ev} =
  ExWebull.TradeEvents.Connection.start_link(
    app_key: "ak", app_secret: "sk",
    accounts: ["ACC-1"], subscribers: [self()]
  )

receive do
  {:webull_trade_event, %ExWebull.TradeEvents.Event{} = e} -> IO.inspect(e)
end
```

## Configuration

```elixir
# config/config.exs
config :ex_webull, :config,
  base_url: "https://api.webull.com",
  mqtt_host: "usquotes-api.webullfintech.com",
  mqtt_port: 8883,
  quotes_host: "api.webull.com",
  quotes_port: 443,
  trade_events_host: "events-api.webull.com",
  trade_events_port: 443,
  region: "US"
```

## Status

HTTP modules are fully tested with `Req.Test`. Protobuf and topic parsing
are tested with round-trip and table-driven tests. The gRPC and MQTT
transport layers compile and are structurally complete, but require live
Webull credentials to exercise end-to-end.

## License

MIT.
