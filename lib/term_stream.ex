defmodule TermStream do
  @moduledoc false
  def serialize(stream, opts \\ []) do
    stream
    |> Stream.map(&:erlang.term_to_binary(&1, opts))
    |> Stream.map(fn entity ->
      size = byte_size(entity)
      <<size::integer-size(32)>> <> entity
    end)
  end

  def deserialize(stream) do
    stream
    |> Stream.chunk_while(
      <<>>,
      fn data, acc ->
        chunks = maybe_pull_chunk(acc <> data)

        {terms, [rest]} =
          Enum.split_with(chunks, fn
            {:term, _} -> true
            _ -> false
          end)

        if terms == [] do
          {:cont, rest}
        else
          {:cont, Enum.map(terms, &elem(&1, 1)), rest}
        end
      end,
      fn data ->
        chunks = maybe_pull_chunk(data)

        {terms, rest} =
          Enum.split_with(chunks, fn
            {:term, _} -> true
            _ -> false
          end)

        if terms == [] do
          {:cont, rest}
        else
          {:cont, Enum.map(terms, &elem(&1, 1)), rest}
        end
      end
    )
    |> Stream.flat_map(& &1)
    |> Stream.map(fn line -> :erlang.binary_to_term(line) end)
  end

  defp maybe_pull_chunk(<<size::integer-size(32), data::binary>>) when byte_size(data) >= size do
    <<tr::binary-size(size), rest::binary>> = data
    [{:term, tr} | maybe_pull_chunk(rest)]
  end

  defp maybe_pull_chunk(e) do
    [e]
  end
end
