defmodule FollowerMaze.Queue.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    num_workers = opts[:num_workers] |> IO.inspect()

    workers =
      Enum.map(1..num_workers, fn i ->
        id = i - 1

        Supervisor.child_spec(
          {FollowerMaze.Queue.Worker,
           [worker_id: id, offset: num_workers, next_seq: i, my_turn: id == 0]},
          id: id
        )
      end)

    childrens = [
      {Registry, [keys: :unique, name: :workers_registry]} | workers
    ]

    Supervisor.init(childrens, strategy: :one_for_one)
  end
end
