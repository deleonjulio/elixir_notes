defmodule ElixirNotesTest do
  use ExUnit.Case
  doctest ElixirNotes

  test "greets the world" do
    assert ElixirNotes.hello() == :world
  end
end
