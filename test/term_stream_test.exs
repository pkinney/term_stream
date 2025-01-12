defmodule TermStreamTest do
  use ExUnit.Case
  use ExUnitProperties

  property "should serialize and deserialize an arbitrary stream of terms" do
    check all(
            terms <-
              StreamData.list_of(StreamData.term()),
            buffer_size <- StreamData.integer(1..(1024 * 1024)),
            max_run_time: 5000,
            max_runs: 1000
          ) do
      {:ok, path} = Briefly.create()
      out_file = File.stream!(path, 1024, [:write, :binary])

      terms
      |> TermStream.serialize()
      |> Stream.into(out_file)
      |> Stream.run()

      File.close(out_file)

      assert path
             |> File.stream!(buffer_size, [:read, :binary])
             |> TermStream.deserialize()
             |> Enum.to_list() ==
               terms
    end
  end

  property "should serialize and deserialize an arbitrary stream of terms with compression" do
    check all(
            terms <-
              StreamData.list_of(StreamData.term()),
            buffer_size <- StreamData.integer(1..(1024 * 1024)),
            max_run_time: 5000,
            max_runs: 1000
          ) do
      {:ok, path} = Briefly.create()
      out_file = File.stream!(path, 1024, [:write, :binary])

      terms
      |> TermStream.serialize(compressed: 9)
      |> Stream.into(out_file)
      |> Stream.run()

      File.close(out_file)

      assert path
             |> File.stream!(buffer_size, [:read, :binary])
             |> TermStream.deserialize()
             |> Enum.to_list() ==
               terms
    end
  end
end
