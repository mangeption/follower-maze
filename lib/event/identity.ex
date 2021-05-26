defmodule FollowerMaze.Event.Identity do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FollowerMaze.hello()
      :world

  """
  alias __MODULE__

  defstruct [
    :user_id
  ]

  @enforce_keys [
    :user_id
  ]
  def parse(s), do: %Identity{user_id: String.to_integer(s)}
end
