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
  def init(opts), do: {:ok, %{clients: MapSet.new(), followers: %{}}}

  @impl true
  def handle_cast({:register, identity, client}, state) do
    Logger.info(~s(Processor registered user #{identity.user_id}))
    {:noreply, %{state | clients: MapSet.put(state.clients, {identity.user_id, client})}}
  end

  @impl true
  def handle_cast({:events, events}, %{followers: followers, clients: clients} = state) do
    msg_map = clients |> Enum.map(&{elem(&1, 0), []}) |> Map.new()
    {followers, msg_map} = Enum.reduce(events, {followers, msg_map}, &handle/2)

    Logger.info(~s(dispatching #{length(events)} events))
    Enum.each(clients, fn {user_id, client} ->
      msgs = Map.get(msg_map, user_id, [])

      Task.Supervisor.start_child(FollowerMaze.Reception.TaskSupervisor, fn ->
        dispatch(client, Enum.reverse(msgs))
      end)
    end)

    # GenServer.cast(FollowerMaze.Dispatcher, {:dispatch, payload})

    {:noreply, %{state | followers: followers}}
  end

  defp dispatch(client, msgs) do
    Enum.each(msgs, fn msg ->
      :gen_tcp.send(client, msg)
    end)
  end

  defp handle(%Event.Follow{from_user: from, to_user: to} = event, {fs, msg_map}) do
    followers = Map.update(fs, from, MapSet.new([to]), &MapSet.put(&1, to))
    msg = Event.render(event)
    {followers, Map.update(msg_map, to, [msg], &[msg | &1])}
  end

  defp handle(%Event.Unfollow{from_user: from, to_user: to} = _e, {fs, msg_map}) do
    {Map.update(fs, from, MapSet.new(), &MapSet.delete(&1, to)), msg_map}
  end

  defp handle(%Event.Broadcast{} = event, {fs, msg_map}) do
    msg = Event.render(event)
    {fs, Enum.into(msg_map, %{}, fn {k, v} -> {k, [msg | v]} end)}
  end

  defp handle(%Event.PrivateMessage{to_user: to} = event, {fs, msg_map}) do
    msg = Event.render(event)
    {fs, Map.update(msg_map, to, [msg], &[msg | &1])}
  end

  defp handle(%Event.StatusUpdate{from_user: from} = event, {fs, msg_map}) do
    msg = Event.render(event)

    msg_map =
      Enum.reduce(msg_map, %{}, fn {k, msgs}, acc ->
        case MapSet.member?(Map.get(fs, k, MapSet.new()), from) do
          true -> Map.put(acc, k, [msg | msgs])
          false -> Map.put(acc, k, msgs)
        end
      end)

    {fs, msg_map}
  end
end
