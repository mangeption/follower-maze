import Config

config :follower_maze, :clients, port: 9099

config :follower_maze, :events, port: 9090

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:file]
