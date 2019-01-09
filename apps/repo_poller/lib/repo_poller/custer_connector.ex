defmodule RepoPoller.ClusterConnector do
  use GenServer

  require Logger

  alias RepoPoller.Config

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init(_) do
    nodes = nodes()
    join_cluster(nodes)
    schedule_self_heal()

    {:ok, nil}
  end

  def handle_info(:self_heal, nil) do
    cluster_nodes = nodes()

    nodes =
      Node.list()
      |> Enum.filter(fn node ->
        Enum.member?(cluster_nodes, node)
      end)

    (cluster_nodes -- nodes)
    |> join_cluster()

    schedule_self_heal()
    {:noreply, nil}
  end

  defp schedule_self_heal() do
    Process.send_after(self(), :self_heal, 5000)
  end

  defp nodes() do
    Config.get_nodes() |> List.delete(Node.self())
  end

  defp join_cluster(nodes) when is_list(nodes) do
    Enum.each(nodes, fn node ->
      Logger.info("joining node #{inspect(node)}")
      join_cluster(node)
    end)
  end

  defp join_cluster(node) do
    Horde.Cluster.join_hordes(
      RepoPoller.DistributedSupervisor,
      {RepoPoller.DistributedSupervisor, node}
    )

    Horde.Cluster.join_hordes(
      RepoPoller.DistributedRegistry,
      {RepoPoller.DistributedRegistry, node}
    )
  end
end
