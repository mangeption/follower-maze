defmodule FollowerMaze.Queue.Worker do
  require Logger
  use GenServer

  alias FollowerMaze.Event

  def start_link(opts) do
    worker_id = opts[:worker_id]
    name = via_tuple(worker_id)
    GenServer.start_link(__MODULE__, opts, name: name, id: worker_id)
  end

  def via_tuple(worker_id), do: {:via, Registry, {:workers_registry, worker_id}}

  alias __MODULE__, as: State

  defstruct [
    :id,
    :my_turn,
    :offset,
    :next_seq,
    :table_name
  ]

  @enforce_keys [
    :id,
    :my_turn,
    :offset,
    :next_seq,
    :table_name
  ]

  @impl true
  def init(opts) do
    worker_id = opts[:worker_id]
    Logger.info(~s(starting worker #{worker_id}))
    table_name = String.to_atom(~s(messages_#{worker_id}))
    :ets.new(table_name, [:set, :private, :named_table])
    {:ok,
     %State{
       my_turn: opts[:my_turn],
       id: worker_id,
       offset: opts[:offset],
       next_seq: opts[:next_seq],
       table_name: table_name
     }}
  end

  @impl true
  def handle_cast(
        {:event, event},
        %State{my_turn: true, next_seq: next_seq, offset: offset} = state
      ) do
    new_state =
      case event.seq == next_seq do
        true ->
          handover(event, state.id, offset)
          %State{state | next_seq: next_seq + offset, my_turn: false}

        false ->
          :ets.insert(state.table_name, {event.seq, event})
          state
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:event, event}, %State{my_turn: false} = state) do
    :ets.insert(state.table_name, {event.seq, event})
    {:noreply, state}
  end

  @imple true
  def handle_cast(
        :your_turn,
        %State{my_turn: false, next_seq: next_seq, offset: offset} = state
      ) do
    updated_state =
      case :ets.lookup(state.table_name, next_seq) do
        [] ->
          %State{state | my_turn: true}

        [{_next_seq, event}] ->
          handover(event, state.id, offset)
          :ets.delete(state.table_name, next_seq)
          %State{state | next_seq: next_seq + offset}
      end

    {:noreply, updated_state}
  end

  @imple true
  def handle_cast(:your_turn, %State{my_turn: true} = state) do
    Logger.error("It's already my turn")
    {:noreply, state}
  end

  defp handover(event, id, num_workers) do
    receivers = handle(event)
    dispatch(event, receivers)
    GenServer.cast(via_tuple(rem(id + 1, num_workers)), :your_turn)
  end

  defp handle(%Event.Follow{from_user: from, to_user: to} = _event) do
    followers =
      case :ets.lookup(:followers, to) do
        [] -> MapSet.new([from])
        [{_from, followers}] -> MapSet.put(followers, from)
      end

    :ets.insert(:followers, {to, followers})

    case :ets.lookup(:clients, to) do
      [] -> []
      [{_to, client}] -> client
    end
  end

  defp handle(%Event.Unfollow{from_user: from, to_user: to} = _event) do
    followers =
      case :ets.lookup(:followers, to) do
        [] -> MapSet.new()
        [{_from, followers}] -> MapSet.delete(followers, from)
      end

    :ets.insert(:followers, {to, followers})

    []
  end

  defp handle(%Event.Broadcast{} = _e), do: Enum.map(:ets.tab2list(:clients), &elem(&1, 1))

  defp handle(%Event.PrivateMessage{to_user: to} = _event) do
    case :ets.lookup(:clients, to) do
      [] -> []
      [{_to, client}] -> client
    end
  end

  defp handle(%Event.StatusUpdate{from_user: from} = _event) do
    followers =
      case :ets.lookup(:followers, from) do
        [] -> []
        [{_from, followers}] -> followers
      end

    Enum.reduce(followers, [], fn follower, acc ->
      case :ets.lookup(:clients, follower) do
        [] -> acc
        [{_follower, client}] -> [client | acc]
      end
    end)
  end

  defp dispatch(event, receivers) when is_list(receivers) do
    msg = Event.render(event)
    Logger.info(~s(dispatching event #{event.seq}))

    Enum.each(receivers, fn client ->
      Task.Supervisor.start_child(FollowerMaze.Reception.TaskSupervisor, fn ->
        :gen_tcp.send(client, msg)
      end)
    end)
  end

  defp dispatch(event, client), do: dispatch(event, [client])
end
