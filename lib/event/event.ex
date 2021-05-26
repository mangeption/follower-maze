defmodule FollowerMaze.Event do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """
  alias __MODULE__

  @doc """
  Hello world.

  ## Examples

      iex> FollowerMaze.hello()
      :world

  """
  def parse(s) do
    case String.split(s, ~s(|)) do
      [seq, "F", from, to] ->
        %Event.Follow{
          seq: String.to_integer(seq),
          from_user: String.to_integer(from),
          to_user: String.to_integer(to)
        }

      [seq, "U", from, to] ->
        %Event.Unfollow{
          seq: String.to_integer(seq),
          from_user: String.to_integer(from),
          to_user: String.to_integer(to)
        }

      [seq, "B"] ->
        %Event.Broadcast{seq: String.to_integer(seq)}

      [seq, "P", from, to] ->
        %Event.PrivateMessage{
          seq: String.to_integer(seq),
          from_user: String.to_integer(from),
          to_user: String.to_integer(to)
        }

      [seq, "S", from] ->
        %Event.StatusUpdate{seq: String.to_integer(seq), from_user: String.to_integer(from)}

      _ ->
        raise ArgumentError, message: "message not supported"
    end
  end

  def render(event) do
    case event do
      %Event.Follow{seq: seq, from_user: from, to_user: to} ->
        ~s(#{seq}|F|#{from}|#{to}\r\n)

      %Event.Unfollow{seq: seq, from_user: from, to_user: to} ->
        ~s(#{seq}|U|#{from}|#{to}\r\n)

      %Event.Broadcast{seq: seq} ->
        ~s(#{seq}|B\r\n)

      %Event.PrivateMessage{seq: seq, from_user: from, to_user: to} ->
        ~s(#{seq}|P|#{from}|#{to}\r\n)

      %Event.StatusUpdate{seq: seq, from_user: from} ->
        ~s(#{seq}|S|#{from}\r\n)

      _ ->
        raise ArgumentError, message: "Event not supported"
    end
  end
end
