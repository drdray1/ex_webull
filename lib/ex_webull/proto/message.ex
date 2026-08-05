defmodule ExWebull.Proto.Message do
  @moduledoc """
  Protobuf modules for MQTT market-push payloads.

  Mirrors the message definitions in the Data Streaming API docs. Every
  payload wraps a `Basic` header carrying symbol, instrument id, and
  timestamp.

  Stocks, futures, and crypto use `Quote`, `Snapshot`, and `Tick`. Event
  contracts use `EventQuote`, `EventSnapshot`, and `EventTick`.
  """
end

defmodule ExWebull.Proto.Message.Basic do
  @moduledoc "Header carried by every market-push payload."
  use Protobuf, syntax: :proto3

  field(:symbol, 1, type: :string)
  field(:instrument_id, 2, type: :string, json_name: "instrumentId")
  field(:timestamp, 3, type: :string)
end

defmodule ExWebull.Proto.Message.Order do
  @moduledoc "A single MPID-attributed order resting at a price level."
  use Protobuf, syntax: :proto3

  field(:mpid, 1, type: :string)
  field(:size, 2, type: :string)
end

defmodule ExWebull.Proto.Message.Broker do
  @moduledoc "A broker quoting at a price level."
  use Protobuf, syntax: :proto3

  field(:bid, 1, type: :string)
  field(:name, 2, type: :string)
end

defmodule ExWebull.Proto.Message.AskBid do
  @moduledoc "One price level of the order book, with its orders and brokers."
  use Protobuf, syntax: :proto3

  field(:price, 1, type: :string)
  field(:size, 2, type: :string)
  field(:order, 3, repeated: true, type: ExWebull.Proto.Message.Order)
  field(:broker, 4, repeated: true, type: ExWebull.Proto.Message.Broker)
end

defmodule ExWebull.Proto.Message.Quote do
  @moduledoc "Real-time order book for stocks, futures, and crypto."
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:asks, 2, repeated: true, type: ExWebull.Proto.Message.AskBid)
  field(:bids, 3, repeated: true, type: ExWebull.Proto.Message.AskBid)
end

defmodule ExWebull.Proto.Message.Snapshot do
  @moduledoc "Market snapshot, including extended-hours (`ext_*`) and overnight (`ovn_*`) session fields."
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
  field(:ext_trade_time, 11, type: :string, json_name: "extTradeTime")
  field(:ext_price, 12, type: :string, json_name: "extPrice")
  field(:ext_high, 13, type: :string, json_name: "extHigh")
  field(:ext_low, 14, type: :string, json_name: "extLow")
  field(:ext_volume, 15, type: :string, json_name: "extVolume")
  field(:ext_change, 16, type: :string, json_name: "extChange")
  field(:ext_change_ratio, 17, type: :string, json_name: "extChangeRatio")
  field(:ovn_trade_time, 18, type: :string, json_name: "ovnTradeTime")
  field(:ovn_price, 19, type: :string, json_name: "ovnPrice")
  field(:ovn_high, 20, type: :string, json_name: "ovnHigh")
  field(:ovn_low, 21, type: :string, json_name: "ovnLow")
  field(:ovn_volume, 22, type: :string, json_name: "ovnVolume")
  field(:ovn_change, 23, type: :string, json_name: "ovnChange")
  field(:ovn_change_ratio, 24, type: :string, json_name: "ovnChangeRatio")
end

defmodule ExWebull.Proto.Message.Tick do
  @moduledoc "A single trade print."
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:time, 2, type: :string)
  field(:price, 3, type: :string)
  field(:volume, 4, type: :string)
  field(:side, 5, type: :string)
end

defmodule ExWebull.Proto.Message.EventAskBid do
  @moduledoc "One price level of an event contract book."
  use Protobuf, syntax: :proto3

  field(:price, 1, type: :string)
  field(:size, 2, type: :string)
end

defmodule ExWebull.Proto.Message.EventQuote do
  @moduledoc "Event contract order book — yes-side and no-side bids."
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:yes_bids, 2, repeated: true, type: ExWebull.Proto.Message.EventAskBid)
  field(:no_bids, 3, repeated: true, type: ExWebull.Proto.Message.EventAskBid)
end

defmodule ExWebull.Proto.Message.EventSnapshot do
  @moduledoc "Event contract snapshot, with both sides of the book and open interest."
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:price, 2, type: :string)
  field(:volume, 3, type: :string)
  field(:last_trade_time, 4, type: :string, json_name: "lastTradeTime")
  field(:open_interest, 5, type: :string, json_name: "openInterest")
  field(:yes_ask, 6, type: :string, json_name: "yesAsk")
  field(:yes_bid, 7, type: :string, json_name: "yesBid")
  field(:yes_ask_size, 8, type: :string, json_name: "yesAskSize")
  field(:yes_bid_size, 9, type: :string, json_name: "yesBidSize")
  field(:no_ask, 10, type: :string, json_name: "noAsk")
  field(:no_bid, 11, type: :string, json_name: "noBid")
  field(:no_ask_size, 12, type: :string, json_name: "noAskSize")
  field(:no_bid_size, 13, type: :string, json_name: "noBidSize")
end

defmodule ExWebull.Proto.Message.EventTick do
  @moduledoc "A single event contract trade print."
  use Protobuf, syntax: :proto3

  field(:basic, 1, type: ExWebull.Proto.Message.Basic)
  field(:yes_price, 2, type: :string, json_name: "yesPrice")
  field(:no_price, 3, type: :string, json_name: "noPrice")
  field(:volume, 4, type: :string)
  field(:side, 5, type: :string)
  field(:trade_id, 6, type: :string, json_name: "tradeId")
  field(:time, 7, type: :string)
end
