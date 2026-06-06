defmodule ExWebull.Proto.Gateway do
  @moduledoc """
  Protobuf modules for the gRPC gateway envelope. The Webull gRPC
  transport uses a single streaming RPC `Quote.StreamRequest` and wraps
  inner payloads (e.g. `InstrumentRequest`) into a `ClientRequest`.

  Corresponds to `priv/proto/gateway.proto`.
  """
end

defmodule ExWebull.Proto.Gateway.MsgType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:Ping, 0)
  field(:Pong, 1)
  field(:Payload, 2)
  field(:Complete, 3)
  field(:Cancel, 4)
  field(:Downgrade, 5)
end

defmodule ExWebull.Proto.Gateway.ClientRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:type, 1, type: ExWebull.Proto.Gateway.MsgType, enum: true)
  field(:requestId, 2, type: :string)
  field(:path, 3, type: :string)
  field(:payload, 4, type: :bytes)
end

defmodule ExWebull.Proto.Gateway.ClientResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:type, 1, type: ExWebull.Proto.Gateway.MsgType, enum: true)
  field(:requestId, 2, type: :string)
  field(:code, 3, type: :uint32)
  field(:msg, 4, type: :string)
  field(:path, 5, type: :string)
  field(:payload, 6, type: :bytes)
end

defmodule ExWebull.Proto.Gateway.Quote.Service do
  @moduledoc false
  use GRPC.Service, name: "openapi.Quote", protoc_gen_elixir_version: "0.13"

  rpc(
    :StreamRequest,
    stream(ExWebull.Proto.Gateway.ClientRequest),
    stream(ExWebull.Proto.Gateway.ClientResponse)
  )
end

defmodule ExWebull.Proto.Gateway.Quote.Stub do
  @moduledoc false
  use GRPC.Stub, service: ExWebull.Proto.Gateway.Quote.Service
end
