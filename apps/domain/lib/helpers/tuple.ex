defmodule Domain.Helpers.Tuple do
  @moduledoc """
  A set of helper functions for working with `tuples`
  """

  @doc """
  Implements `Poison.Encoder` for `Tuple`
  """
  defimpl Poison.Encoder, for: Tuple do

    @doc """
    Converts a key-value `tuple` into a 2 element list for ease of encoding
    """
    def encode({key, value} = tuple, _options) when is_binary(key) do
      Poison.encode!([key, value])
    end

    def encode(tuple, _options) do
      raise Poison.EncodeError, value: tuple
    end
  end
end
