defmodule RepoPoller.MixProject do
  use Mix.Project

  def project do
    [
      app: :repo_poller,
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
      extra_applications: [:logger],
      mod: {RepoPoller.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tentacat, "~> 1.1.0"},
      # use master because there aren't newer releases and master has an API function we need
      {:mock, "~> 0.3.2", only: :test},
      {:bugs_bunny, in_umbrella: true},
      {:domain, in_umbrella: true},
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.3.0", override: true},
      {:mox, "~> 0.4", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
