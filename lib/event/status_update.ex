defmodule FollowerMaze.Event.StatusUpdate do
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
    :seq,
    :from_user
  ]

  @enforce_keys [
    :seq,
    :from_user
  ]
end
