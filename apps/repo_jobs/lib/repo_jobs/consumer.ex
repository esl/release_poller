defmodule RepoJobs.Consumer do
  use GenServer

  def start_link(pool_id) do
    GenServer.start_link(__MODULE__, pool_id)
  end

  def init(pool_id) do
    {:ok, pool_id}
  end
end
