defmodule FollowerMaze.Event.Broadcast do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FollowerMaze.hello()
      :world

  """
  defstruct [
    :seq
  ]

  @enforce_keys [
    :seq
  ]
end
