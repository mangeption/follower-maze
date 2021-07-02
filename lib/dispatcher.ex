defmodule FollowerMaze.Dispatcher do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """
  require Logger
  use GenServer

  alias FollowerMaze.Event

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(opts), do: {:ok, %{clients: %{}, followers: %{}}}

  @impl true
  def handle_cast({:register, identity, client}, state) do
    Logger.info(~s(Dispatcher registered user #{identity.user_id}))
    {:noreply, %{state | clients: Map.put(state.clients, identity.user_id, client)}}
  end

  @impl true
  def handle_cast({:event, event}, %{followers: followers, clients: clients} = state) do
    {new_followers, receivers} = handle(event, followers, clients)

    Logger.info(~s(dispatching event #{event.seq}))
    msg = Event.render(event)

    Enum.each(receivers, fn client ->
      Task.Supervisor.start_child(FollowerMaze.Reception.TaskSupervisor, fn ->
        :gen_tcp.send(client, msg)
      end)
    end)

    {:noreply, %{state | followers: new_followers}}
  end

  defp handle(%Event.Follow{from_user: from, to_user: to} = _e, followers, clients) do
    followers = Map.update(followers, from, MapSet.new([to]), &MapSet.put(&1, to))

    receivers =
      case Map.get(clients, to) do
        nil -> []
        any -> [any]
      end

    {followers, receivers}
  end

  defp handle(%Event.Unfollow{from_user: from, to_user: to} = _e, followers, _clients) do
    {Map.update(followers, from, MapSet.new(), &MapSet.delete(&1, to)), []}
  end

  defp handle(%Event.Broadcast{} = _e, followers, clients) do
    {followers, Map.values(clients)}
  end

  defp handle(%Event.PrivateMessage{to_user: to} = event, followers, clients) do
    receivers =
      case Map.get(clients, to) do
        nil -> []
        any -> [any]
      end

    {followers, receivers}
  end

  defp handle(%Event.StatusUpdate{from_user: from} = event, followers, clients) do
    receivers =
      Enum.reduce(clients, [], fn {user_id, client}, acc ->
        case MapSet.member?(Map.get(followers, user_id, MapSet.new()), from) do
          true -> [client | acc]
          false -> acc
        end
      end)

    {followers, receivers}
  end
end
