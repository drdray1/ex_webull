defmodule ExWebull.Mqtt.Message do
  @moduledoc """
  Decode MQTT market-push payloads to typed protobuf structs.

  Payload type codes match the Python SDK's `payload_type.py`:

    - `0` — `Quote` (`ExWebull.Proto.Message.Quote`)
    - `1` — `Snapshot` (`ExWebull.Proto.Message.Snapshot`)
    - `2` — `Tick` (`ExWebull.Proto.Message.Tick`)

  Unknown payload types fall back to returning the raw bytes tagged
  with the topic's `data_type`.
  """

  alias ExWebull.Mqtt.Topics
  alias ExWebull.Proto.Message

  @payload_type_quote 0
  @payload_type_snapshot 1
  @payload_type_tick 2

  @type decoded ::
          {:quote, Message.Quote.t()}
          | {:snapshot, Message.Snapshot.t()}
          | {:tick, Message.Tick.t()}
          | {:unknown, non_neg_integer(), binary()}

  @doc """
  Decodes a `{topic, payload}` pair into a typed struct tagged with its
  payload category.
  """
  @spec decode(String.t(), binary()) :: {:ok, Topics.t(), decoded()} | {:error, term()}
  def decode(topic, payload) when is_binary(topic) and is_binary(payload) do
    with {:ok, %Topics{data_type: dt} = topic_struct} <- Topics.decode(topic) do
      {:ok, topic_struct, decode_payload(dt, payload)}
    else
      :error -> {:error, {:invalid_topic, topic}}
    end
  end

  @spec decode_payload(non_neg_integer(), binary()) :: decoded()
  def decode_payload(@payload_type_quote, bytes), do: {:quote, Message.Quote.decode(bytes)}

  def decode_payload(@payload_type_snapshot, bytes),
    do: {:snapshot, Message.Snapshot.decode(bytes)}

  def decode_payload(@payload_type_tick, bytes), do: {:tick, Message.Tick.decode(bytes)}
  def decode_payload(other, bytes), do: {:unknown, other, bytes}
end
