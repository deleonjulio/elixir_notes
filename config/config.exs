import Config

config :elixir_notes, ElixirNotes.Repo,
  database: "elixir_notes_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :elixir_notes, ecto_repos: [ElixirNotes.Repo]
