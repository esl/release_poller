defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.Domain.Repo
  alias RepoPoller.Repository.Service

  defmodule State do
    @enforce_keys [:repo]

    @type repo :: Repo.t()
    @type adapter :: atom()
    @type interval :: non_neg_integer()

    @type t :: %__MODULE__{
            repo: repo(),
            adapter: adapter(),
            interval: interval()
          }
    defstruct(repo: nil, adapter: nil, interval: nil)
  end

  def start_link({%{name: repo_name}, _adapter, _interval} = args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom(repo_name))
  end

  @spec init({State.repo(), State.adapter(), State.interval()}) :: {:ok, State.t()}
  def init({repo, adapter, interval}) do
    state = %State{repo: repo, adapter: adapter, interval: interval}
    schedule_poll(0)
    {:ok, state}
  end

  def handle_info(:poll, %{repo: repo, adapter: adapter, interval: interval} = state) do
    %{name: repo_name} = repo

    Logger.info("polling info for repo: #{repo_name}")

    case Service.get_tags(adapter, repo) do
      {:ok, tags} ->
        store_tags(tags)
        schedule_poll(interval)
      {:error, :rate_limit, retry} ->
        Logger.warn("rate limit reached for repo: #{repo_name} retrying in #{retry} ms")
        schedule_poll(retry)
      {:error, reason} ->
        Logger.error("error polling info for repo: #{repo_name} reason: #{inspect reason}")
        schedule_poll(interval)
    end

    {:noreply, state}
  end

  @spec schedule_poll(State.interval()) :: reference()
  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end

  defp store_tags(_tags) do

  end
end
