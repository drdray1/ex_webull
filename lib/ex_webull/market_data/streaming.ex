defmodule ExWebull.MarketData.Streaming do
  @moduledoc """
  Subscription management for the MQTT market-data stream —
  `/openapi/market-data/streaming/*`.

  Subscriptions are keyed by the `session_id` you used as the MQTT
  ClientId, so establish the MQTT connection first:

      {:ok, mqtt} =
        ExWebull.Mqtt.Connection.start_link(
          app_key: "ak", session_id: "my-session", subscribers: [self()]
        )

      ExWebull.MarketData.Streaming.subscribe(md, "my-session", ["AAPL"],
        sub_types: ["SNAPSHOT"]
      )

      ExWebull.Mqtt.Connection.subscribe_topic(mqtt, "snapshot")

  Subscriptions are not restored automatically after a dropped
  connection — re-subscribe on reconnect.
  """

  alias ExWebull.Request

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Subscribes to real-time data
  (`POST /openapi/market-data/streaming/subscribe`).

  `symbols` is a symbol or list of up to 100.

  ## Options

    - `:sub_types` — data types, e.g. `["SNAPSHOT"]`, `["QUOTE"]`,
      `["TICK"]`. Defaults to `["SNAPSHOT"]`.
    - `:category` — default `"US_STOCK"`.
    - `:grab` — whether to grab a snapshot on subscribe, default `"true"`.
    - `:depth` — LV2 depth, default 10 levels, US stocks max 50.
    - `:overnight_required` — include the overnight session (US stocks).
  """
  @spec subscribe(client(), String.t(), String.t() | [String.t()], keyword()) :: response()
  def subscribe(client, session_id, symbols, opts \\ []) do
    Request.post(client, "/openapi/market-data/streaming/subscribe", %{
      session_id: session_id,
      symbols: List.wrap(symbols),
      category: opts[:category] || "US_STOCK",
      sub_types: opts[:sub_types] || ["SNAPSHOT"],
      grab: opts[:grab] || "true",
      depth: opts[:depth],
      overnight_required: opts[:overnight_required]
    })
  end

  @doc """
  Unsubscribes (`POST /openapi/market-data/streaming/unsubscribe`).

  Releases the topic quota. Rate limited to one call per second.

  ## Options

    - `:sub_types` — defaults to `["SNAPSHOT"]`.
    - `:category` — default `"US_STOCK"`.
    - `:unsubscribe_all` — cancel every subscription; `symbols` is then
      ignored by the server.
  """
  @spec unsubscribe(client(), String.t(), String.t() | [String.t()], keyword()) :: response()
  def unsubscribe(client, session_id, symbols, opts \\ []) do
    Request.post(client, "/openapi/market-data/streaming/unsubscribe", %{
      session_id: session_id,
      symbols: List.wrap(symbols),
      category: opts[:category] || "US_STOCK",
      sub_types: opts[:sub_types] || ["SNAPSHOT"],
      unsubscribe_all: opts[:unsubscribe_all]
    })
  end
end
