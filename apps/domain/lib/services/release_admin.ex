defmodule Domain.Services.ReleaseAdmin do
  def get_all_repositories do
    case :rpc.call(:"admin@127.0.0.1", ReleaseAdmin.Repository.Service, :all, []) do
      {:badrpc, reason} ->
        {:error, reason}

      repositories ->
        {:ok, repositories}
    end
  end
end
