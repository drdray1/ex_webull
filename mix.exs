defmodule ExWebull.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/drdray1/ex_webull"

  def project do
    [
      app: :ex_webull,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Elixir client for the Webull OpenAPI",
      package: package(),
      name: "ExWebull",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :ssl],
      mod: {ExWebull.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:decimal, "~> 2.0"},
      {:tortoise311, "~> 0.12"},
      {:grpc, "~> 0.9"},
      {:protobuf, "~> 0.13"},
      {:mint, "~> 1.5"},
      {:plug, "~> 1.14"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.7", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md)
    ]
  end

  defp docs do
    [
      main: "ExWebull",
      extras: ["README.md"],
      groups_for_modules: [
        "REST API": [
          ExWebull.Account,
          ExWebull.Trading,
          ExWebull.Instruments,
          ExWebull.Calendar
        ],
        "Market Data (gRPC)": [
          ExWebull.Market.Candlesticks,
          ExWebull.Market.Snapshot,
          ExWebull.Market.OrderBook,
          ExWebull.Market.Tick,
          ExWebull.Market.Token,
          ExWebull.Market.Subscribe
        ],
        "Streaming (MQTT)": [
          ExWebull.Mqtt.Connection,
          ExWebull.Mqtt.Topics,
          ExWebull.Mqtt.Message
        ],
        "Trade Events (gRPC)": [
          ExWebull.TradeEvents.Connection,
          ExWebull.TradeEvents.Event
        ],
        Authentication: [
          ExWebull.Auth
        ],
        Client: [
          ExWebull.Client,
          ExWebull.Grpc.Client
        ]
      ]
    ]
  end
end
