import Config

config :ex_webull, :config,
  base_url: "https://api.webull.com",
  market_data_base_url: "https://broker-api.webull.com",
  trade_events_host: "events-api.webull.com",
  trade_events_port: 443,
  mqtt_host: "data-api.webull.com",
  mqtt_port: 1883,
  region: "US"
