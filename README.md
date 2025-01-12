# Erlang Term Streaming

![Build Status](https://github.com/pkinney/term_stream/actions/workflows/ci.yaml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/term_stream.svg)](https://hex.pm/packages/term_stream)

A Library for streaming Erlang terms into and out of binary streams. This is especially useful when storing large numbers of Erlang terms to file for later retrieval.

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

## Installation

```elixir
defp deps do
  [{:term_stream, "~> 0.1.0"}]
end
```
