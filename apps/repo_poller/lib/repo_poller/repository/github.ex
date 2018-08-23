defmodule RepoPoller.Repository.Github do
  @behaviour RepoPoller.Repository.Adapter

  alias Tentacat.Client
  alias Tentacat.Repositories.Tags
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  @spec get_tags(Repo.t()) ::
          {:ok, list(Tag.t())} | {:error, :rate_limit, pos_integer()} | {:error, map()}
  def get_tags(%{owner: owner, name: name}) do
    new()
    |> Tags.list(owner, name)
    |> handle_tags_reponse()
  end

  # TODO: FIX specs fo this function
  # RELATED ISSUE: https://github.com/edgurgel/tentacat/issues/144
  # @spec handle_tags_reponse(Tentacat.response()) ::
  #         {:ok, Tag.t()} | {:error, map()} | {:error, :rate_limit, pos_integer()}
  # multiple success clauses due to: https://github.com/edgurgel/tentacat/issues/144
  defp handle_tags_reponse({:ok, json_body, _httpoison_response}) do
    {:ok, map_tags(json_body)}
  end

  defp handle_tags_reponse({200, json_body, _httpoison_response}) do
    {:ok, map_tags(json_body)}
  end

  defp handle_tags_reponse({403, error_body, %{headers: headers}}) do
    {_, rate_limit_remaining} = List.keyfind(headers, "X-RateLimit-Remaining", 0)
    rate_limit_remaining = String.to_integer(rate_limit_remaining, 10)

    if rate_limit_remaining > 0 do
      # error different than a rate-limit error
      {:error, error_body}
    else
      {_, rate_limit_reset} = List.keyfind(headers, "X-RateLimit-Reset", 0)
      rate_limit_reset = String.to_integer(rate_limit_reset, 10)
      rate_limit_reset_dt = DateTime.from_unix!(rate_limit_reset)
      now = DateTime.utc_now()
      retry_in_seconds = DateTime.diff(rate_limit_reset_dt, now)
      {:error, :rate_limit, retry_in_seconds}
    end
  end

  defp handle_tags_reponse({_, error_body, _httpoison_response}), do: {:error, error_body}

  # multiple success clauses due to: https://github.com/edgurgel/tentacat/issues/144
  defp handle_tags_reponse(json_body) do
    {:ok, map_tags(json_body)}
  end

  defp get_access_auth() do
    Application.get_env(:repo_poller, :github_auth)
  end

  @spec new() :: Tentacat.Client.t()
  defp new() do
    case get_access_auth() do
      nil -> Client.new()
      auth -> Client.new(auth)
    end
  end

  defp map_tags(json_body) do
    Enum.map(json_body, &Tag.new/1)
  end
end
