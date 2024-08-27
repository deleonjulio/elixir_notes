defmodule ElixirNotes.User do
  use Ecto.Schema
  import Ecto.Query, warn: false

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string
  end

  def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:name, :email, :password])
    |> Ecto.Changeset.validate_required([:name, :email, :password])
  end

  def login_changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:email, :password])
    |> Ecto.Changeset.validate_required([:email, :password])
  end

  def email_exists?(email) do
    query = from u in ElixirNotes.User, where: u.email == ^email, limit: 1
    ElixirNotes.Repo.one(query) != nil
  end

  def authenticate?(email, password) do
    query = from u in ElixirNotes.User,
      where: u.email == ^email and u.password == ^password,
      limit: 1

    ElixirNotes.Repo.one(query)
  end
end
