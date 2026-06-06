defmodule ExWebull.Proto.Events do
  @moduledoc """
  Protobuf modules + gRPC service stub for the trade-events streaming
  channel. Corresponds to `priv/proto/events.proto`.

  Service: `grpc.trade.event.EventService`, RPC `Subscribe` is a
  server-streaming RPC.
  """
end

defmodule ExWebull.Proto.Events.EventType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:SubscribeSuccess, 0)
  field(:Ping, 1)
  field(:AuthError, 2)
  field(:NumOfConnExceed, 3)
  field(:SubscribeExpired, 4)
end

defmodule ExWebull.Proto.Events.SubscribeRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:subscribeType, 1, type: :uint32)
  field(:timestamp, 2, type: :int64)
  field(:contentType, 3, type: :string)
  field(:payload, 4, type: :string)
  field(:accounts, 5, repeated: true, type: :string)
end

defmodule ExWebull.Proto.Events.SubscribeResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:eventType, 1, type: ExWebull.Proto.Events.EventType, enum: true)
  field(:subscribeType, 2, type: :uint32)
  field(:contentType, 3, type: :string)
  field(:payload, 4, type: :string)
  field(:requestId, 5, type: :string)
  field(:timestamp, 6, type: :int64)
end

defmodule ExWebull.Proto.Events.EventService.Service do
  @moduledoc false
  use GRPC.Service, name: "grpc.trade.event.EventService", protoc_gen_elixir_version: "0.13"

  rpc(
    :Subscribe,
    ExWebull.Proto.Events.SubscribeRequest,
    stream(ExWebull.Proto.Events.SubscribeResponse)
  )
end

defmodule ExWebull.Proto.Events.EventService.Stub do
  @moduledoc false
  use GRPC.Stub, service: ExWebull.Proto.Events.EventService.Service
end
