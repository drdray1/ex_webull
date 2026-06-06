defmodule ExWebull.TradeEvents.Event do
  @moduledoc """
  Normalized trade-event structs delivered to subscribers.

  The underlying gRPC server streams `SubscribeResponse` messages whose
  `payload` is an opaque content-typed string (usually JSON). This
  module converts that into a tagged Elixir struct for ergonomics.
  """

  alias ExWebull.Proto.Events.SubscribeResponse

  defstruct [
    :event_type,
    :subscribe_type,
    :content_type,
    :payload,
    :request_id,
    :timestamp
  ]

  @type t :: %__MODULE__{
          event_type:
            :SubscribeSuccess
            | :Ping
            | :AuthError
            | :NumOfConnExceed
            | :SubscribeExpired,
          subscribe_type: non_neg_integer(),
          content_type: String.t(),
          payload: term(),
          request_id: String.t(),
          timestamp: integer()
        }

  @doc """
  Converts a gRPC `SubscribeResponse` into an `%Event{}`.

  If `contentType` is `"application/json"`, the payload is decoded to
  an Elixir term via `Jason`; otherwise the raw string is passed
  through.
  """
  @spec from_proto(SubscribeResponse.t()) :: t()
  def from_proto(%SubscribeResponse{} = r) do
    %__MODULE__{
      event_type: r.eventType,
      subscribe_type: r.subscribeType,
      content_type: r.contentType,
      payload: decode_payload(r.contentType, r.payload),
      request_id: r.requestId,
      timestamp: r.timestamp
    }
  end

  defp decode_payload("application/json", payload) when is_binary(payload) and payload != "" do
    case Jason.decode(payload) do
      {:ok, term} -> term
      {:error, _} -> payload
    end
  end

  defp decode_payload(_content_type, payload), do: payload
end
