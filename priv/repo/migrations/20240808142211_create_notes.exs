defmodule ElixirNotes.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :content, :text
      add :date_created, :utc_datetime_usec
      add :date_updated, :utc_datetime_usec
      add :user_id, :integer
      add :deleted, :boolean
    end
  end
end
