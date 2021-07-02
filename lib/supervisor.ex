defmodule FollowerMaze.Supervisor do
  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:followers, [:set, :public, :named_table])
    :ets.new(:clients, [:set, :public, :named_table])
    queue_config = Application.get_env(:follower_maze, :queue)

    server_config =
      Application.get_env(:follower_maze, :server)
      |> Keyword.put(:num_workers, queue_config[:num_workers])

    children = [
      {FollowerMaze.Server, server_config},
      {Task.Supervisor, name: FollowerMaze.Reception.TaskSupervisor},
      {FollowerMaze.Reception, Application.get_env(:follower_maze, :clients)},
      {Task.Supervisor, name: FollowerMaze.Dispatcher.TaskSupervisor},
      {FollowerMaze.Queue.Supervisor, queue_config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
