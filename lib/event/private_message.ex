defmodule FollowerMaze.Event.PrivateMessage do
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
    :from_user,
    :to_user
  ]

  @enforce_keys [
    :seq,
    :from_user,
    :to_user
  ]
end
