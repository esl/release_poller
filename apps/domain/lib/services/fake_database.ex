defmodule Domain.Services.FakeDatabase do
  alias Domain.Services.Database
  @behaviour Database

  @impl true
  def get_all_repositories do
    {:ok, []}
  end
end
