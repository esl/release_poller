defmodule RepoJobs.Config do
  def get_github_access_token() do
    Application.get_env(:repo_jobs, :github_auth) || System.get_env("GITHUB_AUTH")
  end

  def get_consumers() do
    Application.get_env(:repo_jobs, :consumers)
  end

  def get_connection_pool_config() do
    Application.get_env(:repo_jobs, :rabbitmq_conn_pool, [])
  end

  def get_connection_pool_id() do
    get_connection_pool_config()
    |> Keyword.fetch!(:pool_id)
  end

  def get_rabbitmq_config() do
    Application.get_env(:repo_jobs, :rabbitmq_config, [])
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

  def temp_dir() do
    Application.get_env(:repo_jobs, :tmp_dir, System.tmp_dir!())
  end
end
