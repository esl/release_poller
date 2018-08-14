defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.DB
  alias RepoPoller.Domain.{Repo, Tag}
  alias RepoPoller.Repository.Service

  defmodule State do
    @enforce_keys [:repo]

    @type adapter :: module()
    @type interval :: non_neg_integer()

    @type t :: %__MODULE__{
            repo: Repo.t(),
            adapter: adapter(),
            interval: interval()
          }
    defstruct(repo: nil, adapter: nil, interval: nil)
  end

  def start_link({%{name: repo_name}, _adapter, _interval} = args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom(repo_name))
  end

  @spec init({Repo.t(), State.adapter(), State.interval()}) :: {:ok, State.t()}
  def init({repo, adapter, interval}) do
    state = %State{repo: repo, adapter: adapter, interval: interval}
    schedule_poll(0)
    {:ok, state}
  end

  def handle_info(:poll, %{repo: repo, adapter: adapter, interval: interval} = state) do
    %{name: repo_name} = repo

    Logger.info("polling info for repo: #{repo_name}")

    new_state =
      case Service.get_tags(adapter, repo) do
        {:ok, tags} ->
          state = %State{state | repo: update_repo_tags(repo, tags)}
          schedule_poll(interval)
          state

        {:error, :rate_limit, retry} ->
          Logger.warn("rate limit reached for repo: #{repo_name} retrying in #{retry} ms")
          schedule_poll(retry)
          state

        {:error, reason} ->
          Logger.error("error polling info for repo: #{repo_name} reason: #{inspect(reason)}")
          schedule_poll(interval)
          state
      end

    {:noreply, new_state}
  end

  @spec schedule_poll(State.interval()) :: reference()
  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end

  @spec update_repo_tags(Repo.t(), list(Tag.t())) :: Repo.t()
  defp update_repo_tags(repo, tags) do
    DB.get_tags(repo)
    |> Tag.new_tags?(tags)
    |> if do
      new_repo = Repo.set_tags(repo, tags)
      :ok = DB.save(new_repo)
      new_repo

      # TODO: schedule jobs
    else
      repo
    end
  end
end
