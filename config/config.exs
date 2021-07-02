import Config

config :follower_maze, :clients, port: 9099

config :follower_maze, :server, port: 9090

config :follower_maze, :queue, num_workers: 2

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:file]
