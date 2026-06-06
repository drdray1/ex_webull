import Config

config :ex_webull, :config,
  base_url: "https://api.webull.com",
  trade_events_host: "events-api.webull.com",
  trade_events_port: 443,
  quotes_host: "api.webull.com",
  quotes_port: 443,
  mqtt_host: "usquotes-api.webullfintech.com",
  mqtt_port: 8883,
  region: "US"
