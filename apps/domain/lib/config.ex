defmodule Domain.Config do
  def get_admin_domain do
    Application.get_env(:domain, :admin_domain, :"admin@127.0.0.1")
  end
end
