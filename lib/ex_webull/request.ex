defmodule ExWebull.Request do
  @moduledoc """
  Thin request helpers shared by the endpoint modules.

  Every endpoint module is a set of one-liners over `get/3` and `post/3`.
  Both drop `nil` values before sending, so optional parameters can be
  passed through unconditionally, and both unwrap the response through
  `ExWebull.Client.handle_response/1`.
  """

  alias ExWebull.Client

  @type client :: Req.Request.t()
  @type response :: {:ok, term()} | {:error, term()}

  @doc "Issues a GET, dropping `nil` query params."
  @spec get(client(), String.t(), keyword()) :: response()
  def get(client, path, params \\ []) do
    client
    |> Req.get(url: path, params: compact(params))
    |> Client.handle_response()
  end

  @doc "Issues a POST with a JSON body, dropping `nil` members."
  @spec post(client(), String.t(), map() | keyword()) :: response()
  def post(client, path, body \\ %{}) do
    client
    |> Req.post(url: path, json: body |> compact() |> Map.new())
    |> Client.handle_response()
  end

  @doc """
  Normalises a symbol argument into the comma-separated form the API
  expects. Accepts a single symbol or a list.
  """
  @spec symbols(String.t() | [String.t()]) :: String.t()
  def symbols(symbols) when is_list(symbols), do: Enum.join(symbols, ",")
  def symbols(symbol) when is_binary(symbol), do: symbol

  @doc "Drops `nil` values from a keyword list or map."
  @spec compact(keyword() | map()) :: keyword() | [{term(), term()}]
  def compact(enum), do: Enum.reject(enum, fn {_k, v} -> is_nil(v) end)
end
