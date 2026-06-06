defmodule ExWebull.Mqtt.Handler do
  @moduledoc """
  Tortoise311 handler for Webull market-push — forwards every received
  PUBLISH to the owning `ExWebull.Mqtt.Connection` GenServer.
  """

  use Tortoise311.Handler
  require Logger

  @impl true
  def init(args) do
    {:ok, %{owner: Keyword.fetch!(args, :owner), ref: Keyword.fetch!(args, :ref)}}
  end

  @impl true
  def handle_message(topic_list, payload, %{owner: owner} = state) when is_list(topic_list) do
    topic = Enum.join(topic_list, "/")
    send(owner, {:webull_mqtt_message, topic, payload})
    {:ok, state}
  end

  @impl true
  def connection(status, state) do
    Logger.debug("ExWebull.Mqtt.Handler connection: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def subscription(status, topic, state) do
    Logger.debug("ExWebull.Mqtt.Handler subscription #{topic}: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state), do: :ok
end
