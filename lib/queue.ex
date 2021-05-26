defmodule FollowerMaze.Queue do
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
  def init(_opts) do
    Logger.info("starting event queue")

    {:ok, %{queue: [], cur_seq: 1}}
  end

  @impl true
  def handle_cast({:event, event}, %{queue: queue, cur_seq: cur_seq} = state) do
    with true <- event.seq == cur_seq,
         sorted_queue <- Enum.sort_by(queue, & &1.seq, :asc),
         {new_queue, result, new_seq} <- drain(sorted_queue, [event], cur_seq + 1) do
      :ok = GenServer.cast(FollowerMaze.Dispatcher, {:events, Enum.reverse(result)})
      {:noreply, %{queue: new_queue, cur_seq: new_seq}}
    else
      _ -> {:noreply, %{queue: [event | queue], cur_seq: cur_seq}}
    end
  end

  defp drain([], acc, cur_seq), do: {[], acc, cur_seq}

  defp drain([head | rest] = sorted_queue, acc, cur_seq) do
    case head.seq == cur_seq do
      false -> {sorted_queue, acc, cur_seq}
      true -> drain(rest, [head | acc], cur_seq + 1)
    end
  end
end
