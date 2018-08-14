defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.Domain.Repo

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

  def handle_info(:poll, %{repo: repo, interval: interval} = state) do
    %{name: repo_name} = repo

    Logger.info("polling info for repo: #{repo_name}")

    schedule_poll(interval)
    {:noreply, state}
  end

  @spec schedule_poll(State.interval()) :: reference()
  def schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end
end
