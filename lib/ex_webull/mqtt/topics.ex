defmodule ExWebull.Mqtt.Topics do
  @moduledoc """
  Encode/parse Webull market-push MQTT topic strings.

  Topic format: `"<instrument_id>-<data_type_code>-<interval>"`.

  The Python SDK's split-on-`-` is careful with instruments containing
  a dash — it requires `len(segments) > 3` before accepting the topic.
  We follow the same rule: the last two segments are always the data
  type and interval; everything before is the instrument id (which may
  contain dashes).
  """

  @enforce_keys [:instrument_id, :data_type, :interval]
  defstruct [:instrument_id, :data_type, :interval]

  @type t :: %__MODULE__{
          instrument_id: String.t(),
          data_type: non_neg_integer(),
          interval: non_neg_integer()
        }

  @doc "Decodes a topic string. Returns `{:ok, topic}` or `:error`."
  @spec decode(String.t()) :: {:ok, t()} | :error
  def decode(""), do: :error
  def decode(nil), do: :error

  def decode(topic) when is_binary(topic) do
    case String.split(topic, "-") do
      segments when length(segments) > 3 ->
        [interval, data_type | instrument_parts_rev] = Enum.reverse(segments)
        instrument_id = instrument_parts_rev |> Enum.reverse() |> Enum.join("-")

        with {dt, ""} <- Integer.parse(data_type),
             {iv, ""} <- Integer.parse(interval) do
          {:ok, %__MODULE__{instrument_id: instrument_id, data_type: dt, interval: iv}}
        else
          _ -> :error
        end

      [instrument_id, data_type, interval] ->
        with {dt, ""} <- Integer.parse(data_type),
             {iv, ""} <- Integer.parse(interval) do
          {:ok, %__MODULE__{instrument_id: instrument_id, data_type: dt, interval: iv}}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  @doc "Encodes a topic struct back into the wire format."
  @spec encode(t()) :: String.t()
  def encode(%__MODULE__{instrument_id: iid, data_type: dt, interval: iv}) do
    "#{iid}-#{dt}-#{iv}"
  end
end
