defmodule ExWebull.Market.Token do
  @moduledoc """
  Streaming token over gRPC (`/market-data/streaming/token`).

  The returned token is used as the MQTT connection credential when
  opening `ExWebull.Mqtt.Connection`.
  """

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{SubscribeRequest, TokenResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc "Fetches a streaming token for MQTT auth."
  @spec get(Client.t()) :: response()
  def get(client) do
    # The token endpoint takes no parameters; the Python SDK still
    # wraps an (empty) SubscribeRequest-shaped payload at that path.
    Client.request(
      client,
      "/market-data/streaming/token",
      %SubscribeRequest{},
      SubscribeRequest,
      TokenResponse
    )
  end
end
