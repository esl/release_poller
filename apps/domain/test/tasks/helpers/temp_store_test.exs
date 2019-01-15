defmodule Domain.Tasks.Helpers.TempStoreTest do
  use ExUnit.Case, async: false

  alias Domain.Tasks.Helpers.TempStore

  @moduletag :integration

  setup do
    n = :rand.uniform(100)
    # create random directory so it can run concurrently
    base_dir = Path.join([System.cwd!(), "test", "fixtures", "temp", to_string(n)])

    on_exit(fn ->
      File.rm_rf!(base_dir)
    end)

    {:ok, base_dir: base_dir}
  end

  describe "create_tmp_dir/2" do
    test "creates a new tmp directory", %{base_dir: base_dir} do
      assert {:ok, dir_path} = TempStore.create_tmp_dir(["elixir-lang", "elixir"], base_dir)
      assert dir_path == "#{base_dir}/elixir-lang/elixir"
      assert File.dir?(dir_path)
    end

    test "doesn't fail if tries to create an already existing directory", %{base_dir: base_dir} do
      already_existing_dir = Path.join([base_dir, "exists"])
      assert :ok = File.mkdir_p!(already_existing_dir)
      assert {:ok, ^already_existing_dir} = TempStore.create_tmp_dir(["exists"], base_dir)
      assert File.dir?(already_existing_dir)
    end

    test "returns error tuple is there was an error" do
      # root
      base_dir = "/"
      assert {:error, :eacces} = TempStore.create_tmp_dir(["not_allowed"], base_dir)
    end
  end

  describe "generate_destination_path/2" do
    test "returns the prefered destination given a URL", %{base_dir: base_dir} do
      url = "https://github.com/elixir-lang/elixir"

      assert TempStore.generate_destination_path(base_dir, url) ==
               "#{base_dir}/elixir-lang/elixir"
    end
  end
end
