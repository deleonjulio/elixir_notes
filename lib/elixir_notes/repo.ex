defmodule ElixirNotes.Repo do
  use Ecto.Repo,
    otp_app: :elixir_notes,
    adapter: Ecto.Adapters.Postgres
end
