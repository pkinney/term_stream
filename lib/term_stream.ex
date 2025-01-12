defmodule TermStream do
  @moduledoc """
  A Library for streaming Erlang terms into and out of binary streams. This is especially useful when storing large numbers of Erlang terms to file for later retrieval. When dealing with large files containing lots of Erlang terms, having to load the entire list into memory can be problematice. Using `TermStream` allows you to stream the terms one at a time out of the file.


  ## Example

  ```elixir
  # To write a stream of terms to a file:

  file = File.stream!("my_file", [:write, :binary])

  other_stream
  |> TermStream.serialize()
  |> Stream.into(file)
  |> Stream.run()

  File.close(file)

  # The get a stream out of the same file later:

  File.stream!("my_file", 1024, [:read, :binary])
  |> TermStream.deserialize()
  |> Stream.run()

  ```

  """

  @doc """
  Takes a stream of erlang terms and returns a stream of binary data representing those terms that is suitable for writing to a file without newlines or other delimiters.

  This function takes an optional `opts` argument that is passed to `:erlang.term_to_binary/2`. This can be used to control the compression or other parameters of the serialization. See the documentation for `:erlang.term_to_binary/2` for more information.
  """
  def serialize(stream, opts \\ []) do
    stream
    |> Stream.map(&:erlang.term_to_binary(&1, opts))
    |> Stream.map(fn entity ->
      size = byte_size(entity)
      <<size::integer-size(32)>> <> entity
    end)
  end

  @doc """
  Takes a stream of binary data representing erlang terms (as written by `TermStream.serialize/1` and returns a stream of the original terms.
  """
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
