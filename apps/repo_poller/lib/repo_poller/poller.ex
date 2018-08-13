defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.Domain.Repo

  @one_minute 60 * 1000

  defmodule State do
    @enforce_keys [:repo]

    @type repo :: Repo.t()
    @type interval :: pos_integer()

    @type t :: %__MODULE__{
            repo: repo(),
            interval: interval()
          }
    defstruct(repo: nil, interval: nil)

    @spec new(repo(), interval()) :: RepoPoller.Poller.State.t()
    def new(repo, interval) do
      %State{repo: repo, interval: interval}
    end
  end

  def start_link(%{name: repo_name} = repo, interval \\ @one_minute) do
    GenServer.start_link(__MODULE__, {repo, interval}, name: String.to_atom(repo_name))
  end

  @spec init({State.repo(), State.interval()}) :: {:ok, State.t()}
  def init({repo, interval}) do
    state = State.new(repo, interval)
    schedule_poll(state)
    {:ok, state}
  end

  def handle_info(:poll, state) do
    schedule_poll(state)
    {:noreply, state}
  end

  @spec schedule_poll(State.t()) :: reference()
  def schedule_poll(%{repo: repo, interval: interval}) do
    %{name: repo_name} = repo

    Logger.info("scheduling poll for repo: #{repo_name}")

    repo_name
    |> String.to_existing_atom()
    |> Process.send_after(:poll, interval)
  end
end
