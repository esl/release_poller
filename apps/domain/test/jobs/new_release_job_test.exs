defmodule Domain.Serializers.NewReleaseJob.Test do
  use ExUnit.Case, async: true

  alias Domain.Jobs.NewReleaseJob
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  test "creates a single new release job" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")

    tag = %Tag{
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

    assert job = NewReleaseJob.new(repo, tag)

    assert job == %NewReleaseJob{
             new_tag: tag,
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }
  end

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

    assert [job] = NewReleaseJob.new(repo, tags)

    assert job == %NewReleaseJob{
             new_tag: %Tag{
               commit: %{
                 sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
                 url:
                   "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
               },
               name: "v1.7.2",
               node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
               tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
               zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
             },
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }
  end

  test "creates multiple release jobs" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")

    tag1 = %Tag{
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

    tag2 = %Tag{
      commit: %{
        sha: "8aab53b941ee955f005e7b4e08c333f0b94c48b7",
        url:
          "https://api.github.com/repos/elixir-lang/elixir/commits/8aab53b941ee955f005e7b4e08c333f0b94c48b7"
      },
      name: "v1.7.1",
      node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjE=",
      tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.1",
      zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.1"
    }

    tags = [tag1, tag2]

    assert [job1, job2] = NewReleaseJob.new(repo, tags)

    assert job1 == %NewReleaseJob{
             new_tag: tag1,
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }

    assert job2 == %NewReleaseJob{
             new_tag: tag2,
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }
  end
end
