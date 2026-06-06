defmodule ExWebull.Proto.Quote do
  @moduledoc """
  Protobuf modules for gRPC quotes — request/response types used over
  the `/market-data/*` gRPC paths. Corresponds to `priv/proto/quote.proto`.
  """
end

defmodule ExWebull.Proto.Quote.Instrument do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:name, 1, type: :string)
  field(:symbol, 2, type: :string)
  field(:instrument_id, 3, type: :string, json_name: "instrumentId")
  field(:exchange_code, 4, type: :string, json_name: "exchangeCode")
  field(:currency, 5, type: :string)
end

defmodule ExWebull.Proto.Quote.InstrumentRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbols, 1, type: :string)
  field(:category, 2, type: :string)
end

defmodule ExWebull.Proto.Quote.InstrumentResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:result, 1, repeated: true, type: ExWebull.Proto.Quote.Instrument)
end

defmodule ExWebull.Proto.Quote.Bar do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:time, 1, type: :string)
  field(:open, 2, type: :string)
  field(:close, 3, type: :string)
  field(:high, 4, type: :string)
  field(:low, 5, type: :string)
  field(:volume, 6, type: :string)
end

defmodule ExWebull.Proto.Quote.BarsRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:category, 2, type: :string)
  field(:timespan, 3, type: :string)
  field(:count, 4, type: :string)
  field(:real_time_required, 5, type: :string, json_name: "realTimeRequired")
  field(:trading_sessions, 6, type: :string, json_name: "tradingSessions")
end

defmodule ExWebull.Proto.Quote.BarsResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:result, 3, repeated: true, type: ExWebull.Proto.Quote.Bar)
end

defmodule ExWebull.Proto.Quote.BatchBarsRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbols, 1, repeated: true, type: :string)
  field(:category, 2, type: :string)
  field(:timespan, 3, type: :string)
  field(:count, 4, type: :int32)
  field(:real_time_required, 5, type: :string, json_name: "realTimeRequired")
  field(:trading_sessions, 6, repeated: true, type: :string, json_name: "tradingSessions")
end

defmodule ExWebull.Proto.Quote.BatchBarsResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:result, 1, repeated: true, type: ExWebull.Proto.Quote.BarsResponse)
end

defmodule ExWebull.Proto.Quote.Snapshot do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:trade_time, 3, type: :string, json_name: "tradeTime")
  field(:price, 4, type: :string)
  field(:open, 5, type: :string)
  field(:high, 6, type: :string)
  field(:low, 7, type: :string)
  field(:pre_close, 8, type: :string, json_name: "preClose")
  field(:volume, 9, type: :string)
  field(:change, 10, type: :string)
  field(:change_ratio, 11, type: :string, json_name: "changeRatio")
end

defmodule ExWebull.Proto.Quote.SnapshotRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbols, 1, type: :string)
  field(:category, 2, type: :string)
end

defmodule ExWebull.Proto.Quote.SnapshotResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:result, 1, repeated: true, type: ExWebull.Proto.Quote.Snapshot)
end

defmodule ExWebull.Proto.Quote.TokenResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:token, 1, type: :string)
end

defmodule ExWebull.Proto.Quote.SubscribeRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:token, 1, type: :string)
  field(:symbols, 2, repeated: true, type: :string)
  field(:category, 3, type: :string)
  field(:sub_types, 4, repeated: true, type: :string, json_name: "subTypes")
  field(:unsubscribe_all, 5, type: :string, json_name: "unsubscribeAll")
end

defmodule ExWebull.Proto.Quote.SubscribeResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3
end

defmodule ExWebull.Proto.Quote.Order do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:mpid, 1, type: :string)
  field(:size, 2, type: :string)
end

defmodule ExWebull.Proto.Quote.Broker do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:bid, 1, type: :string)
  field(:name, 2, type: :string)
end

defmodule ExWebull.Proto.Quote.AskBid do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:price, 1, type: :string)
  field(:size, 2, type: :string)
  field(:order, 3, repeated: true, type: ExWebull.Proto.Quote.Order)
  field(:broker, 4, repeated: true, type: ExWebull.Proto.Quote.Broker)
end

defmodule ExWebull.Proto.Quote.QuoteRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:category, 2, type: :string)
end

defmodule ExWebull.Proto.Quote.QuoteResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:asks, 3, repeated: true, type: ExWebull.Proto.Quote.AskBid)
  field(:bids, 4, repeated: true, type: ExWebull.Proto.Quote.AskBid)
end

defmodule ExWebull.Proto.Quote.Tick do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:time, 1, type: :string)
  field(:price, 2, type: :string)
  field(:volume, 3, type: :string)
  field(:side, 4, type: :string)
end

defmodule ExWebull.Proto.Quote.TickRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:category, 2, type: :string)
  field(:count, 3, type: :string)
end

defmodule ExWebull.Proto.Quote.TickResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:result, 3, repeated: true, type: ExWebull.Proto.Quote.Tick)
end
