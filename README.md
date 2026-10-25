# ExWebull

An Elixir client for the [Webull OpenAPI](https://developer.webull.com/apis/docs/).

Covers the current (`x-version: v2`) API surface:

- **Trading** — unified order placement, preview, replace, cancel, and
  batch place across equities, options, futures, crypto, and event
  contracts; order history, open orders, order detail, and the
  settlement activity ledger.
- **Accounts** — account list, balances, and option-aware positions.
- **Instruments** — stock, option contract, futures, crypto, and event
  contract reference data, plus company profiles and analyst coverage.
- **Market data** — snapshots, quotes, ticks, bars, and footprint for
  every asset class; NOII, screeners, watchlists, and news summaries.
- **Fundamentals** — financial statements, indicators, calendars,
  filings, capital flow, and fund data.
- **Streaming** — MQTT market data with protobuf decoding, and gRPC
  trade events with JSON-decoded payloads.

All signed requests use Webull's HMAC-SHA1 scheme, verified against the
reference vectors in the signature docs.

## Installation

```elixir
def deps do
  [
    {:ex_webull, "~> 0.1.2"}
  ]
end
```

## Two clients

Trading and market data are served from different hosts, so build one
client for each:

```elixir
trade = ExWebull.Client.new("app_key", "app_secret")
md    = ExWebull.Client.new_market_data("app_key", "app_secret")
```

If your account has Two-Factor Authentication enabled, create a token,
verify the SMS code in the Webull app within 5 minutes, then pass it to
the client:

```elixir
{:ok, %{"token" => token}} = ExWebull.Token.create(trade)
{:ok, %{"status" => "NORMAL"}} = ExWebull.Token.check(trade, token)

trade = ExWebull.Client.new("app_key", "app_secret", access_token: token)
```

Store and reuse a valid token — it stays good until 15 consecutive days
without an API call.

## Quick start

### Trading

```elixir
{:ok, accounts} = ExWebull.Account.list(trade)
{:ok, balance}  = ExWebull.Assets.balance(trade, "ACC-1")

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

ExWebull.Trading.cancel_order(trade, "ACC-1", resp["client_order_id"])
```

### Options

Options go through the same order endpoints, with `instrument_type:
"OPTION"`, an `option_strategy`, and a `legs` array. Multi-leg
strategies — `VERTICAL`, `IRON_CONDOR`, `COVERED_STOCK`, and the rest —
are just more legs.

```elixir
ExWebull.Trading.place_order(trade, "ACC-1", %{
  client_order_id: "unique-id",
  combo_type: "NORMAL",
  instrument_type: "OPTION",
  option_strategy: "SINGLE",
  market: "US",
  symbol: "AAPL",
  side: "BUY",
  order_type: "LIMIT",
  limit_price: "11.25",
  quantity: "1",
  entrust_type: "QTY",
  time_in_force: "DAY",
  legs: [
    %{
      side: "BUY",
      quantity: "1",
      symbol: "AAPL",
      strike_price: "220.00",
      option_expire_date: "2026-06-19",
      instrument_type: "OPTION",
      option_type: "CALL",
      market: "US"
    }
  ]
})
```

### Reading options trades

Order queries return combo orders whose `orders[].legs[]` carry full
contract detail:

```elixir
{:ok, combos} =
  ExWebull.Trading.order_history(trade, "ACC-1",
    start_date: "2026-01-01", end_date: "2026-01-31", page_size: 100
  )

for combo <- combos,
    order <- combo["orders"],
    order["instrument_type"] == "OPTION",
    leg <- order["legs"] do
  IO.puts("""
  #{order["position_intent"]} #{leg["quantity"]}x \
  #{leg["symbol"]} #{leg["option_expire_date"]} \
  #{leg["strike_price"]}#{String.first(leg["option_type"])} \
  @ #{order["filled_price"]} (#{order["filled_time_at"]})
  """)
end

# Open positions, with strategy and legs
{:ok, positions} = ExWebull.Assets.positions(trade, "ACC-1")

# Settlement ledger — fills, commissions, fees — to reconcile against
{:ok, activities} =
  ExWebull.Trading.activities(trade, "ACC-1", activity_types: "TRADE")

# Static contract data for enrichment
{:ok, contracts} =
  ExWebull.Instruments.options(trade, option_symbol: "AAPL260619C00180000")
```

### Market data

```elixir
alias ExWebull.MarketData

{:ok, snap}  = MarketData.Stock.snapshot(md, ["AAPL", "TSLA"])
{:ok, bars}  = MarketData.Stock.bars(md, "AAPL", "D", count: 30)
{:ok, greek} = MarketData.Option.snapshot(md, "AAPL260619C00180000")
{:ok, top}   = MarketData.Screener.top_active(md, rank_type: "TURNOVER")
{:ok, fin}   = ExWebull.Fundamentals.Financial.income(md, "AAPL", type: "ANNUAL")
```

### Streaming market data (MQTT)

Pick a `session_id`, connect, then tell Webull what to push:

```elixir
{:ok, mqtt} =
  ExWebull.Mqtt.Connection.start_link(
    app_key: "ak", session_id: "my-session", subscribers: [self()]
  )

ExWebull.MarketData.Streaming.subscribe(md, "my-session", ["AAPL"],
  sub_types: ["SNAPSHOT"]
)

ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "snapshot")

receive do
  {:webull_event, "snapshot", {:snapshot, snap}} -> IO.inspect(snap)
end
```

Topics are `quote`, `snapshot`, `tick`, their `event-` variants for
event contracts, plus `notice` and `echo`. Each app key allows 5
concurrent connections, and subscriptions are not restored automatically
after a reconnect.

### Trade events (gRPC)

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
  market_data_base_url: "https://broker-api.webull.com",
  mqtt_host: "data-api.webull.com",
  mqtt_port: 1883,
  trade_events_host: "events-api.webull.com",
  trade_events_port: 443,
  region: "US"
```

## Scope

The Broker API (account opening, ACH and wire funding, journals, fees,
and the Display Solution market-data tier) is not covered — it targets
brokerage partners with separate credentials.

## Status

HTTP modules are tested with `Req.Test`, protobuf messages by
round-trip tests, and the MQTT and gRPC connections against mocked
transports covering connect, stream consumption, error frames, and
teardown. Neither transport is exercised against live Webull servers.

`mix test --cover` enforces a minimum of 86%; the suite currently runs
at 99.6%.

## License

MIT.
