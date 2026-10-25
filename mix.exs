defmodule ExWebull.MixProject do
  use Mix.Project

  @version "0.1.2"
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
      docs: docs(),
      test_coverage: test_coverage()
    ]
  end

  # `mix test --cover` fails the run below this line.
  #
  # The ignored modules have no code of ours to exercise: `Fixtures` is
  # test support, and the three generated modules are a single `use`
  # macro each (`GRPC.Service`, `GRPC.Stub`, and a protobuf enum). The
  # gRPC stub is in fact driven by the trade-events tests, but Mimic
  # replaces the module, so cover cannot see it.
  defp test_coverage do
    [
      threshold: 86,
      ignore_modules: [
        ExWebull.Fixtures,
        ExWebull.Proto.Events.EventType,
        ExWebull.Proto.Events.EventService.Service,
        ExWebull.Proto.Events.EventService.Stub,
        ~r/\.Mimic\.Original\.Module$/
      ]
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
      {:decimal, "~> 2.0 or ~> 3.0"},
      {:tortoise311, "~> 0.12"},
      {:grpc, "~> 1.0"},
      {:protobuf, "~> 0.13"},
      {:mint, "~> 1.9"},
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
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "ExWebull",
      extras: ["README.md"],
      groups_for_modules: [
        "Trading & Accounts": [
          ExWebull.Account,
          ExWebull.Assets,
          ExWebull.Trading
        ],
        Instruments: [
          ExWebull.Instruments
        ],
        "Market Data": [
          ExWebull.MarketData.Stock,
          ExWebull.MarketData.Option,
          ExWebull.MarketData.Futures,
          ExWebull.MarketData.Crypto,
          ExWebull.MarketData.Event,
          ExWebull.MarketData.Screener,
          ExWebull.MarketData.Watchlist,
          ExWebull.News
        ],
        Fundamentals: [
          ExWebull.Fundamentals.Stock,
          ExWebull.Fundamentals.Financial,
          ExWebull.Fundamentals.Fund
        ],
        "Streaming (MQTT)": [
          ExWebull.MarketData.Streaming,
          ExWebull.Mqtt.Connection,
          ExWebull.Mqtt.Topics,
          ExWebull.Mqtt.Message
        ],
        "Trade Events (gRPC)": [
          ExWebull.TradeEvents.Connection,
          ExWebull.TradeEvents.Event
        ],
        Authentication: [
          ExWebull.Auth,
          ExWebull.Token,
          ExWebull.OAuth
        ],
        Client: [
          ExWebull.Client,
          ExWebull.Request
        ]
      ]
    ]
  end
end
