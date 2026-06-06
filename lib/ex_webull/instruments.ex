defmodule ExWebull.Instruments do
  @moduledoc """
  Webull Instruments endpoints — lookup securities, tradable lists, and
  corporate actions.
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Lists instruments by symbols and category (`GET /instrument/list`).

  ## Params
    - `symbols` — comma-separated list (e.g. `"AAPL,TSLA"`)
    - `category` — e.g. `"US_STOCK"`
  """
  @spec list(client(), String.t(), String.t()) :: response()
  def list(client, symbols, category) do
    client
    |> Req.get(url: "/instrument/list", params: [symbols: symbols, category: category])
    |> Client.handle_response()
  end

  @doc "Fetches corporate actions (`GET /instrument/corp-action`)."
  @spec corp_action(client(), keyword()) :: response()
  def corp_action(client, opts \\ []) do
    client
    |> Req.get(url: "/instrument/corp-action", params: drop_nil(opts))
    |> Client.handle_response()
  end

  @doc "Fetches a trade instrument detail (`GET /trade/instrument`)."
  @spec trade_instrument(client(), keyword()) :: response()
  def trade_instrument(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/instrument", params: drop_nil(opts))
    |> Client.handle_response()
  end

  @doc "Fetches a trade security detail (`GET /trade/security`)."
  @spec trade_security(client(), keyword()) :: response()
  def trade_security(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/security", params: drop_nil(opts))
    |> Client.handle_response()
  end

  @doc "Lists tradable instruments (`GET /trade/instrument/tradable/list`)."
  @spec tradable(client(), keyword()) :: response()
  def tradable(client, opts \\ []) do
    client
    |> Req.get(url: "/trade/instrument/tradable/list", params: drop_nil(opts))
    |> Client.handle_response()
  end

  defp drop_nil(kw), do: Enum.reject(kw, fn {_k, v} -> is_nil(v) end)
end
