defmodule BugsBunny.MixProject do
  use Mix.Project

  def project do
    [
      app: :bugs_bunny,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # https://github.com/pma/amqp/issues/90
      extra_applications: [:lager, :logger, :amqp]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 1.0"},
      # amqp and tentacat depends on jsx
      {:jsx, "2.8.2", override: true},
      # https://github.com/pma/amqp/issues/99
      {:ranch, "1.5.0", override: true},
      # https://github.com/pma/amqp/issues/99
      {:ranch_proxy_protocol, "~> 2.0", override: true},
      {:poolboy, "~> 1.5"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
