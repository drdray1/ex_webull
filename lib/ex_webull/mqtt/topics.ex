defmodule ExWebull.Mqtt.Topics do
  @moduledoc """
  The MQTT topics Webull publishes market data on.

  | Topic | Payload | Applies to |
  |---|---|---|
  | `quote` | protobuf `Quote` | stocks, futures, crypto |
  | `snapshot` | protobuf `Snapshot` | stocks, futures, crypto |
  | `tick` | protobuf `Tick` | stocks, futures, crypto |
  | `event-quote` | protobuf `EventQuote` | event contracts |
  | `event-snapshot` | protobuf `EventSnapshot` | event contracts |
  | `event-tick` | protobuf `EventTick` | event contracts |
  | `notice` | JSON | server notifications |
  | `echo` | empty | heartbeat / online check |

  Which symbols arrive on a topic is controlled by
  `ExWebull.MarketData.Streaming.subscribe/4`, not by the topic name.
  """

  @topics ~w(quote snapshot tick event-quote event-snapshot event-tick notice echo)

  @market_topics ~w(quote snapshot tick)
  @event_topics ~w(event-quote event-snapshot event-tick)

  @doc "Every topic Webull publishes on."
  @spec all() :: [String.t()]
  def all, do: @topics

  @doc "The stock / futures / crypto data topics."
  @spec market() :: [String.t()]
  def market, do: @market_topics

  @doc "The event-contract data topics."
  @spec event() :: [String.t()]
  def event, do: @event_topics

  @doc "Returns true when `topic` is one Webull publishes on."
  @spec known?(String.t()) :: boolean()
  def known?(topic) when is_binary(topic), do: topic in @topics
  def known?(_), do: false
end
