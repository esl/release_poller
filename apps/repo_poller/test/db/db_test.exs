defmodule ReleasePoller.DBTest do
  use ExUnit.Case

  alias RepoPoller.DB
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  setup do
    dialyxir =
      Repo.new("https://github.com/jeremyjh/dialyxir")
      |> Repo.set_tags([
        %Tag{name: "v0.3.1"},
        %Tag{name: "v0.3.0"},
        %Tag{name: "1.0.0-rc.3"},
        %Tag{name: "1.0.0-rc.2"},
        %Tag{name: "1.0.0-rc.1"},
        %Tag{name: "1.0.0-rc.0"},
        %Tag{name: "0.5.1"},
        %Tag{name: "0.4.4"},
        %Tag{name: "0.4.3"},
        %Tag{name: "0.4.2"},
        %Tag{name: "0.4.1"},
        %Tag{name: "0.4.0"},
        %Tag{name: "0.3.5"},
        %Tag{name: "0.3.4"},
        %Tag{name: "0.3.3"},
        %Tag{name: "0.3.2"}
      ])

    elixir =
      Repo.new("https://github.com/elixir-lang/elixir")
      |> Repo.set_tags([
        %Tag{name: "v1.7.2"},
        %Tag{name: "v1.7.1"},
        %Tag{name: "v1.7.0"},
        %Tag{name: "v1.7.0-rc.1"},
        %Tag{name: "v1.7.0-rc.0"},
        %Tag{name: "v1.6.6"},
        %Tag{name: "v1.6.5"},
        %Tag{name: "v1.6.4"},
        %Tag{name: "v1.6.3"},
        %Tag{name: "v1.6.2"},
        %Tag{name: "v1.6.1"},
        %Tag{name: "v1.6.0"},
        %Tag{name: "v1.6.0-rc.1"},
        %Tag{name: "v1.6.0-rc.0"}
      ])

    on_exit(fn ->
      DB.clear()
    end)

    {:ok, repos: [dialyxir, elixir]}
  end

  describe "save/2" do
    test "saves repos with its tags", %{repos: repos} do
      for repo <- repos do
        assert :ok = DB.save(repo)
      end

      repos = :ets.tab2list(:repo_tags)
      assert length(repos) == 2

      repo_names = Enum.map(repos, fn {name, _} -> name end)

      assert Enum.member?(repo_names, "dialyxir")
      assert Enum.member?(repo_names, "elixir")
    end

    test "saves are persisted to disk", %{repos: repos} do
      for repo <- repos do
        assert :ok = DB.save(repo)
      end

      db_name = Application.get_env(:repo_poller, :db_name)
      assert File.regular?(db_name)
    end
  end

  describe "get_tags/1" do
    setup %{repos: repos} do
      for repo <- repos do
        assert :ok = DB.save(repo)
      end
      :ok
    end

    test "gets repo tags", %{repos: repos} do
      [dialyxir, elixir] = repos
      # not saved
      other = Repo.new("https://github.com/fake/other")

      assert DB.get_tags(dialyxir) == dialyxir.tags
      assert DB.get_tags(elixir) == elixir.tags
      assert DB.get_tags(other) == []
    end
  end
end
