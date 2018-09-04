defmodule RepoPoller.Config do
  def get_github_access_token() do
    Application.get_env(:repo_poller, :github_auth, System.get_env("GITHUB_AUTH"))
  end

  def get_repos() do
    Application.get_env(:repo_poller, :repos, [])
  end

  def get_connection_pool_config() do
    Application.get_env(:repo_poller, :rabbitmq_conn_pool, [])
  end

  def get_connection_pool_id() do
    get_connection_pool_config()
    |> Keyword.fetch!(:pool_id)
  end

  def get_rabbitmq_config() do
    Application.get_env(:repo_poller, :rabbitmq_config, [])
  end

  def get_rabbitmq_queue() do
    get_rabbitmq_config()
    |> Keyword.fetch!(:queue)
  end

  def get_rabbitmq_exchange() do
    get_rabbitmq_config()
    |> Keyword.fetch!(:exchange)
  end

  def get_rabbitmq_client() do
    get_rabbitmq_config()
    |> Keyword.get(:client, BugsBunny.RabbitMQ)
  end

  def get_rabbitmq_reconnection_interval() do
    get_rabbitmq_config()
    |> Keyword.get(:reconnect, 5000)
  end

  def get_db_name() do
    Application.get_env(:repo_poller, :db_name) || System.get_env("DB_NAME") || "releases.tab"
  end
end
