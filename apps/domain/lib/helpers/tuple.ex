defmodule Domain.Helpers.Tuple do
  defimpl Poison.Encoder, for: Tuple do
    def encode({key, value} = tuple, _options) when is_binary(key) do
      Poison.encode!([key, value])
    end

    def encode(tuple, _options) do
      raise Poison.EncodeError, value: tuple
    end
  end
end
