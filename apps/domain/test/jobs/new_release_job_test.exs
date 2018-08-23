defmodule Domain.Serializers.NewReleaseJob.Test do
  use ExUnit.Case, async: true

  alias Domain.Jobs.NewReleaseJob
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  test "creates a new release job" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")

    tags = [
      %Tag{
        commit: %{
          sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
          url:
            "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
        },
        name: "v1.7.2",
        node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
        tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
        zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
      }
    ]

    job = NewReleaseJob.new(repo, tags)

    assert job == %NewReleaseJob{
             new_tags: [
               %Tag{
                 commit: %{
                   sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
                   url:
                     "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
                 },
                 name: "v1.7.2",
                 node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
                 tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
                 zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
               }
             ],
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }
  end
end
