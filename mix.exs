defmodule ReleasePoller.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      elixir: "~> 1.7",
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [flags: [:error_handling, :race_conditions, :underspecs]]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:excoveralls, "~> 0.9", only: :test},
      {:lager, "3.6.5", override: true},
      {:jsx, "2.8.2", override: true},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:credo, "~> 1.5.6", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0"}
    ]
  end
end
