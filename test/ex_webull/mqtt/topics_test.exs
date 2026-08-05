defmodule ExWebull.Mqtt.TopicsTest do
  use ExUnit.Case, async: true

  alias ExWebull.Mqtt.Topics

  test "all/0 covers the documented topics" do
    assert Enum.sort(Topics.all()) ==
             Enum.sort(~w(quote snapshot tick event-quote event-snapshot event-tick notice echo))
  end

  test "market/0 and event/0 partition the data topics" do
    assert Topics.market() == ~w(quote snapshot tick)
    assert Topics.event() == ~w(event-quote event-snapshot event-tick)
    assert Enum.all?(Topics.market() ++ Topics.event(), &Topics.known?/1)
  end

  test "known?/1 rejects unknown or non-binary topics" do
    refute Topics.known?("913256135-1-1000")
    refute Topics.known?("")
    refute Topics.known?(nil)
    refute Topics.known?(:snapshot)
  end
end
