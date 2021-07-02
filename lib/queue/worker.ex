defmodule FollowerMaze.Queue.Worker do
  require Logger
  use GenServer

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
    :msgs
  ]

  @enforce_keys [
    :id,
    :my_turn,
    :offset,
    :next_seq,
    :msgs
  ]

  @impl true
  def init(opts) do
    Logger.info(~s(starting worker #{opts[:worker_id]}))

    {:ok,
     %State{
       my_turn: opts[:my_turn],
       id: opts[:worker_id],
       offset: opts[:offset],
       next_seq: opts[:next_seq],
       msgs: %{}
     }}
  end

  @impl true
  def handle_cast(
        {:event, event},
        %State{my_turn: true, next_seq: next_seq, offset: offset, msgs: msgs} = state
      ) do
    new_state =
      case event.seq == next_seq do
        true ->
          handover(event, state.id, offset)
          %State{state | next_seq: next_seq + offset, my_turn: false}

        false ->
          %State{state | msgs: Map.put(msgs, event.seq, event)}
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:event, event}, %State{my_turn: false, msgs: msgs} = state) do
    {:noreply, %State{state | msgs: Map.put(msgs, event.seq, event)}}
  end

  @imple true
  def handle_cast(
        :your_turn,
        %State{my_turn: false, next_seq: next_seq, offset: offset, msgs: msgs} = state
      ) do
    updated_state =
      case Map.pop(msgs, next_seq) do
        {nil, _} ->
          %State{state | my_turn: true}

        {msg, updated_msgs} ->
          handover(msg, state.id, offset)
          %State{state | msgs: updated_msgs, next_seq: next_seq + offset}
      end

    {:noreply, updated_state}
  end

  @imple true
  def handle_cast(:your_turn, %State{my_turn: true} = state) do
    Logger.error("It's already my turn")
    {:noreply, state}
  end

  defp handover(event, id, num_workers) do
    GenServer.cast(FollowerMaze.Dispatcher, {:event, event})
    GenServer.cast(via_tuple(rem(id + 1, num_workers)), :your_turn)
  end
end
