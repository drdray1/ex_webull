defmodule ExWebull.Proto.Message do
  @moduledoc """
  Protobuf modules for MQTT market-push payloads.

  Corresponds to `priv/proto/message.proto` in the Webull SDK. The
  message types are used for `snapshot`, `quote`, and `tick` streams
  that flow over the MQTT push channel.
  """
end

defmodule ExWebull.Proto.Message.Basic do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:timestamp, 3, type: :string)
end

defmodule ExWebull.Proto.Message.Snapshot do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:trade_time, 2, type: :string, json_name: "tradeTime")
  field(:price, 3, type: :string)
  field(:open, 4, type: :string)
  field(:high, 5, type: :string)
  field(:low, 6, type: :string)
  field(:pre_close, 7, type: :string, json_name: "preClose")
  field(:volume, 8, type: :string)
  field(:change, 9, type: :string)
  field(:change_ratio, 10, type: :string, json_name: "changeRatio")
end

defmodule ExWebull.Proto.Message.Order do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:mpid, 1, type: :string)
  field(:size, 2, type: :string)
end

defmodule ExWebull.Proto.Message.Broker do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:bid, 1, type: :string)
  field(:name, 2, type: :string)
end

defmodule ExWebull.Proto.Message.AskBid do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:price, 1, type: :string)
  field(:size, 2, type: :string)
  field(:order, 3, repeated: true, type: ExWebull.Proto.Message.Order)
  field(:broker, 4, repeated: true, type: ExWebull.Proto.Message.Broker)
end

defmodule ExWebull.Proto.Message.Quote do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:asks, 2, repeated: true, type: ExWebull.Proto.Message.AskBid)
  field(:bids, 3, repeated: true, type: ExWebull.Proto.Message.AskBid)
end

defmodule ExWebull.Proto.Message.Tick do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:time, 2, type: :string)
  field(:price, 3, type: :string)
  field(:volume, 4, type: :string)
  field(:side, 5, type: :string)
end
