defmodule Domain.Tags.TagTest do
  use ExUnit.Case, async: true

  alias Domain.Tags.Tag

  test "creates a new tag" do
    tag_map = %{
      "name" => "v0.1",
      "commit" => %{
        "sha" => "c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
        "url" =>
          "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
      },
      "zipball_url" => "https://github.com/octocat/Hello-World/zipball/v0.1",
      "tarball_url" => "https://github.com/octocat/Hello-World/tarball/v0.1"
    }

    assert %Tag{
             name: "v0.1",
             commit: %{
               sha: "c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
               url:
                 "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
             },
             zipball_url: "https://github.com/octocat/Hello-World/zipball/v0.1",
             tarball_url: "https://github.com/octocat/Hello-World/tarball/v0.1"
           } == Tag.new(tag_map)
  end

  test "has new tags" do
    # no version 1.7.*
    old = [
      %Tag{name: "v1.6.6"},
      %Tag{name: "v1.6.5"},
      %Tag{name: "v1.6.4"},
      %Tag{name: "v1.6.3"},
      %Tag{name: "v1.6.2"},
      %Tag{name: "v1.6.1"},
      %Tag{name: "v1.6.0"},
      %Tag{name: "v1.6.0-rc.1"},
      %Tag{name: "v1.6.0-rc.0"}
    ]

    # with version 1.7.*
    new = [
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
    ]

    assert Tag.new_tags(old, new) == [
             %Tag{name: "v1.7.2"},
             %Tag{name: "v1.7.1"},
             %Tag{name: "v1.7.0"},
             %Tag{name: "v1.7.0-rc.1"},
             %Tag{name: "v1.7.0-rc.0"}
           ]
  end

  test "hasn new tags - unsorted tags" do
    # no version 1.7.*
    old = [
      %Tag{name: "v1.6.6"},
      %Tag{name: "v1.6.5"},
      %Tag{name: "v1.6.4"},
      %Tag{name: "v1.6.3"},
      %Tag{name: "v1.6.2"},
      %Tag{name: "v1.6.1"},
      %Tag{name: "v1.6.0"},
      %Tag{name: "v1.6.0-rc.1"},
      %Tag{name: "v1.6.0-rc.0"}
    ]

    # with version 1.7.*
    new = [
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
    ]

    new_tags = Tag.new_tags(Enum.shuffle(old), Enum.shuffle(new))
    assert Enum.member?(new_tags, %Tag{name: "v1.7.2"})
    assert Enum.member?(new_tags, %Tag{name: "v1.7.1"})
    assert Enum.member?(new_tags, %Tag{name: "v1.7.0"})
    assert Enum.member?(new_tags, %Tag{name: "v1.7.0-rc.1"})
    assert Enum.member?(new_tags, %Tag{name: "v1.7.0-rc.0"})
  end

  test "hasn't new tags - with tags" do
    old = [
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
    ]

    new = [
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
    ]

    assert Tag.new_tags(old, new) == []
  end

  test "hasn't new tags - without tags" do
    old = []
    new = []
    assert Tag.new_tags(old, new) == []
  end

  test "hasn't new tags - unsorted tags" do
    old = [
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
    ]

    new = [
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
    ]

    assert Tag.new_tags(Enum.shuffle(old), Enum.shuffle(new)) == []
  end
end
