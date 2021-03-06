defmodule Slack.Mixfile do
  use Mix.Project

  def project do
    [app: :slack,
     version: "0.7.2",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     dialyzer: [plt_add_apps: [:poison], flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :httpotion],
      mod: {Slack, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpotion, "~> 3.1.3"},
      {:socket, "~> 0.3.12"},
      {:jason, "~> 1.2"},
      {:mix_test_watch, "~> 1.0", only: :dev},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:queue, "~> 0.1.0", github: "zvkemp/ex-queues"},
    ]
  end
end
