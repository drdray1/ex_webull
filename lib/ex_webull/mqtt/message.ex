defmodule ExWebull.Mqtt.Message do
  @moduledoc """
  Decode MQTT market-push payloads.

  The topic determines the payload type — see `ExWebull.Mqtt.Topics`.
  Protobuf topics decode to structs under `ExWebull.Proto.Message`,
  `notice` decodes as JSON, and `echo` is an empty heartbeat.
  """

  alias ExWebull.Proto.Message

  @type decoded ::
          {:quote, Message.Quote.t()}
          | {:snapshot, Message.Snapshot.t()}
          | {:tick, Message.Tick.t()}
          | {:event_quote, Message.EventQuote.t()}
          | {:event_snapshot, Message.EventSnapshot.t()}
          | {:event_tick, Message.EventTick.t()}
          | {:notice, map()}
          | :echo
          | {:unknown, String.t(), binary()}

  @doc """
  Decodes a `{topic, payload}` pair.

  Returns `{:ok, topic, decoded}`, or `{:error, {:invalid_payload, topic,
  reason}}` when a payload cannot be parsed. Unrecognised topics are
  returned as `{:unknown, topic, raw_bytes}` rather than an error, so a
  new server-side topic does not crash the connection.
  """
  @spec decode(String.t(), binary()) :: {:ok, String.t(), decoded()} | {:error, term()}
  def decode(topic, payload) when is_binary(topic) and is_binary(payload) do
    {:ok, topic, decode_payload(topic, payload)}
  rescue
    e -> {:error, {:invalid_payload, topic, e}}
  end

  @doc "Decodes a payload for a known topic name."
  @spec decode_payload(String.t(), binary()) :: decoded()
  def decode_payload("quote", bytes), do: {:quote, Message.Quote.decode(bytes)}
  def decode_payload("snapshot", bytes), do: {:snapshot, Message.Snapshot.decode(bytes)}
  def decode_payload("tick", bytes), do: {:tick, Message.Tick.decode(bytes)}

  def decode_payload("event-quote", bytes),
    do: {:event_quote, Message.EventQuote.decode(bytes)}

  def decode_payload("event-snapshot", bytes),
    do: {:event_snapshot, Message.EventSnapshot.decode(bytes)}

  def decode_payload("event-tick", bytes),
    do: {:event_tick, Message.EventTick.decode(bytes)}

  def decode_payload("notice", bytes), do: {:notice, Jason.decode!(bytes)}
  def decode_payload("echo", _bytes), do: :echo
  def decode_payload(topic, bytes), do: {:unknown, topic, bytes}
end
