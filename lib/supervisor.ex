defmodule FollowerMaze.Supervisor do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {FollowerMaze.Server, Application.get_env(:follower_maze, :events)},
      {Task.Supervisor, name: FollowerMaze.Reception.TaskSupervisor},
      {FollowerMaze.Reception, Application.get_env(:follower_maze, :clients)},
      {FollowerMaze.Queue, []},
      {FollowerMaze.Dispatcher, []},
      {Task.Supervisor, name: FollowerMaze.Dispatcher.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
