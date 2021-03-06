defmodule FollowerMaze.Server do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """
  require Logger
  use GenServer

  alias FollowerMaze.Event
  alias FollowerMaze.Queue

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("starting server")

    {:ok, socket} =
      :gen_tcp.listen(opts[:port], [:binary, packet: :line, active: true, reuseaddr: true])

    send(self(), :accept)

    {:ok,
     %{
       socket: socket,
       next_seq: 1,
       num_workers: opts[:num_workers]
     }}
  end

  @impl true
  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)
    Logger.info("Server accepted socket")
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:tcp, socket, packet},
        %{num_workers: num_workers} = state
      ) do
    event = Event.parse(String.trim(packet))
    # Logger.info(~s(#{event.seq} #{String.trim(packet)}))
    worker_id = rem(event.seq - 1, num_workers)
    :ok = GenServer.cast(Queue.Worker.via_tuple(worker_id), {:event, event})

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_error, socket}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    {:noreply, state}
  end
end
