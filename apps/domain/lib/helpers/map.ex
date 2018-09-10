defmodule Domain.Helpers.Map do
  @moduledoc """
  A set of helper functions for working with `maps`
  """

  @doc """
  Returns a new `map` where all its `key`s are converted from `String` to `Atom`
  """
  @spec safe_map_keys_to_atom(map()) :: map()
  def safe_map_keys_to_atom(map) do
    for {key, val} <- map, into: %{} do
      if is_map(val) do
        {String.to_existing_atom(key), safe_map_keys_to_atom(val)}
      else
        {String.to_existing_atom(key), val}
      end
    end
  end
end
