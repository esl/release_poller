defmodule Domain.Tasks.Task do
  @moduledoc """
  Represents the task that is going to be executed when there is a new release of
  a repository.

  A task is a one particular action meant to be downloaded from an external
  source via a `source` module, and to be executed via a `runner` module,
  which is going to have access to the new release tag as a environment variable
  and a list of environment variables assigned via its `env` attribute.

  It is going to be executed by a `runner` module, defaults to: `Domain.Tasks.Runners.Make`,
  and its going to be downloaded by a `source` module, defaults to `Domain.Tasks.Sources.Github`.

  The task can contain multiple commands:

      make -f Makefile install
      make -f Makefile build
      make -f Makefile release
      make -f Makefile deploy
  """
  alias __MODULE__
  alias Domain.Tasks.Runners.Make
  alias Domain.Tasks.Sources.Github

  @type runner :: module()
  # TODO: add support for other sources e.g GitLab etc
  @type source :: module()

  @type t :: %__MODULE__{
          url: String.t(),
          build_file: Path.t(),
          build_file_content: String.t(),
          path: Path.t(),
          env: list(),
          commands: list(String.t()),
          runner: runner(),
          source: source()
        }

  defstruct url: nil,
            build_file: nil,
            build_file_content: [],
            path: nil,
            env: [],
            commands: [],
            runner: Make,
            source: Github

  @spec new(Enum.t()) :: Task.t() | no_return()
  def new(attrs) do
    struct!(__MODULE__, attrs)
    |> expand_build_file()
  end

  @spec expand_build_file(Task.t()) :: Task.t()
  defp expand_build_file(%{build_file: nil} = task), do: task

  defp expand_build_file(%{build_file: path} = task) do
    priv_dir = :code.priv_dir(:repo_poller) |> to_string()

    content =
      Path.join([priv_dir, path])
      |> File.read!()

    %Task{task | build_file_content: content}
  end
end
