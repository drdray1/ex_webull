defmodule ExWebull.Market.Subscribe do
  @moduledoc """
  Subscribe / unsubscribe topics over gRPC
  (`/market-data/streaming/subscribe` and `/unsubscribe`).

  These calls tell the server what streams to push to the associated
  MQTT connection identified by `token`.
  """

  alias ExWebull.Grpc.Client
  alias ExWebull.Proto.Quote.{SubscribeRequest, SubscribeResponse}

  @type response :: {:ok, struct()} | {:error, term()}

  @doc """
  Subscribes to streams for the given symbols.

  ## Parameters
    - `token` — the token returned by `ExWebull.Market.Token.get/1`
    - `symbols` — list of symbols (e.g. `["AAPL", "TSLA"]`)
    - `category` — e.g. `"US_STOCK"`
    - `sub_types` — list of subscription type strings
  """
  @spec subscribe(Client.t(), String.t(), [String.t()], String.t(), [String.t()]) :: response()
  def subscribe(client, token, symbols, category, sub_types) do
    req = %SubscribeRequest{
      token: token,
      symbols: symbols,
      category: category,
      sub_types: sub_types
    }

    Client.request(
      client,
      "/market-data/streaming/subscribe",
      req,
      SubscribeRequest,
      SubscribeResponse
    )
  end

  @doc "Unsubscribes from streams. Pass `unsubscribe_all: \"true\"` to drop everything."
  @spec unsubscribe(Client.t(), String.t(), [String.t()], String.t(), [String.t()], keyword()) ::
          response()
  def unsubscribe(client, token, symbols, category, sub_types, opts \\ []) do
    req = %SubscribeRequest{
      token: token,
      symbols: symbols,
      category: category,
      sub_types: sub_types,
      unsubscribe_all: Keyword.get(opts, :unsubscribe_all, "")
    }

    Client.request(
      client,
      "/market-data/streaming/unsubscribe",
      req,
      SubscribeRequest,
      SubscribeResponse
    )
  end
end
