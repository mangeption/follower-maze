defmodule FollowerMaze.Reception do
  @moduledoc """
  Documentation for `FollowerMaze`.
  """
  require Logger
  use GenServer

  alias __MODULE__, as: State
  alias FollowerMaze.Event

  defstruct [
    :socket,
    :clients,
    :followers
  ]

  @enforce_keys [
    :socket,
    :clients,
    :followers
  ]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("starting reception")

    {:ok, socket} =
      :gen_tcp.listen(opts[:port], [:binary, packet: :line, active: false, reuseaddr: true])

    send(self(), :accept)

    {:ok,
     %State{
       socket: socket,
       clients: %{},
       followers: %{}
     }}
  end

  @impl true
  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, client} = :gen_tcp.accept(socket)

    reception = self()

    {:ok, _} =
      Task.Supervisor.start_child(FollowerMaze.Reception.TaskSupervisor, fn ->
        serve(client, reception)
      end)

    send(self(), :accept)
    {:noreply, state}
  end

  defp serve(socket, reception) do
    {:ok, packet} = :gen_tcp.recv(socket, 0)
    identity = Event.Identity.parse(String.trim(packet))
    :ets.insert(:clients, {identity.user_id, socket})
    Logger.info(~s(#{identity.user_id} #{String.trim(packet)}))
  end
end
