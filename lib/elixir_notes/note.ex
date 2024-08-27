defmodule ElixirNotes.Note do
  use Ecto.Schema
  import Ecto.Query, warn: false

  schema "notes" do
    field :content, :string
    field :date_created, :utc_datetime_usec
    field :date_updated, :utc_datetime_usec
    field :user_id, :integer
    field :deleted, :boolean
  end

  def changeset(note, params \\ %{}) do
    note
    |> Ecto.Changeset.cast(params, [:content, :date_created, :date_updated, :user_id, :deleted])
    |> Ecto.Changeset.validate_required([:user_id])
  end

  def create(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      note = %ElixirNotes.Note{}
      changeset = ElixirNotes.Note.changeset(note, %{content: "", date_created: DateTime.utc_now, date_updated: DateTime.utc_now, user_id: session.id, deleted: false})
      if changeset.valid? do
        case ElixirNotes.Repo.insert(changeset) do
          {:ok, data} ->
            data = Map.from_struct(data) |> Map.delete(:__meta__) |> Map.delete(:user_id)
            response_body = %{message: "Note created successfully.", data: data} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)
          {:error, _} ->
            response_body = %{error: "Something went wrong."} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)
        end
      else
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
        response_body = %{error: errors} |> Jason.encode!()
        conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(400, response_body)
      end
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def update_note(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      conn = Plug.Conn.fetch_query_params(conn)
      {:ok, content} = Map.fetch(conn.body_params, "content")
      {:ok, noteId} = Map.fetch(conn.body_params, "noteId")

      note = ElixirNotes.Note
        |> where([note], note.id == ^noteId and note.user_id == ^session.id)
        |> Ecto.Query.first()
        |> ElixirNotes.Repo.one()

      changeset = ElixirNotes.Note.changeset(note, %{content: content, date_updated: DateTime.utc_now})
      if changeset.valid? do
        case ElixirNotes.Repo.update(changeset) do
          {:ok, updated_note} ->
            data = Map.from_struct(updated_note) |> Map.delete(:date_created) |> Map.delete(:__meta__) |> Map.delete(:user_id)
            response_body = %{message: "Note updated successfully.", data: data} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)

          {:error, _error} ->
            response_body = %{error: "Something went wrong."} |> Jason.encode!()
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(500, response_body)
        end
      else
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
        response_body = %{error: errors} |> Jason.encode!()
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(400, response_body)
      end
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def delete(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      conn = Plug.Conn.fetch_query_params(conn)
      noteId = conn.params["id"]

      note = ElixirNotes.Note
        |> where([note], note.id == ^noteId and note.user_id == ^session.id)
        |> Ecto.Query.first()
        |> ElixirNotes.Repo.one()

      changeset = ElixirNotes.Note.changeset(note, %{deleted: true})

      if changeset.valid? do
        case ElixirNotes.Repo.update(changeset) do
          {:ok, _} ->
            response_body = %{message: "Note deleted successfully."} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)

          {:error, _} ->
            response_body = %{error: "Something went wrong."} |> Jason.encode!()
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(500, response_body)
        end
      else
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
        response_body = %{error: errors} |> Jason.encode!()
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(400, response_body)
      end
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def get(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      query = from note in ElixirNotes.Note,
              where: note.user_id == ^session.id and note.deleted == false,
              order_by: [desc: note.date_updated],
              select: %{
                id: note.id,
                content: note.content,
                date_updated: note.date_updated
              },
              limit: 100
      data = ElixirNotes.Repo.all(query)
      # data = remove_meta_from_list(data)
      response_body = %{message: "Notes fetched successfully.", data: data} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, response_body)
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def search(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      search_string = conn.params["search_string"]
      search_string = "%#{search_string}%"
      query = from note in ElixirNotes.Note,
              where: note.user_id == ^session.id and note.deleted == false and ilike(note.content, ^search_string),
              order_by: [desc: note.date_updated],
              select: %{
                id: note.id,
                content: note.content,
                date_updated: note.date_updated
              }

      data = ElixirNotes.Repo.all(query)

      response_body = %{message: "Notes fetched successfully.",  data: data} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, response_body)
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def preload_notes(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      conn = Plug.Conn.fetch_query_params(conn)
      {:ok, date} = Map.fetch(conn.body_params, "date")
      {:ok, date} = NaiveDateTime.from_iso8601(date)

      query_greater = from note in ElixirNotes.Note,
        where: note.user_id == ^session.id and note.deleted == false and note.date_updated >= ^date,
        order_by: [asc: note.date_updated],
        select: %{
          id: note.id,
          content: note.content,
          date_updated: note.date_updated
        },
        limit: 100

      query_less = from note in ElixirNotes.Note,
        where: note.user_id == ^session.id and note.deleted == false and note.date_updated < ^date,
        order_by: [desc: note.date_updated],
        select: %{
          id: note.id,
          content: note.content,
          date_updated: note.date_updated
        },
        limit: 100

      records_greater = ElixirNotes.Repo.all(query_greater)
      records_greater = Enum.reverse(records_greater)
      records_less = ElixirNotes.Repo.all(query_less)

      combined_records = records_greater ++ records_less

      response_body = %{message: "Notes fetched successfully.", data: combined_records} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, response_body)
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def load_more_notes(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false

    if authenticated do
      conn = Plug.Conn.fetch_query_params(conn)
      {:ok, position} = Map.fetch(conn.body_params, "position")
      {:ok, date} = Map.fetch(conn.body_params, "date")
      {:ok, date} = NaiveDateTime.from_iso8601(date)

      if position == "BOTTOM" do
        oldest_note_query = from note in ElixirNotes.Note,
          where: note.user_id == ^session.id and note.deleted == false,
          order_by: [asc: note.date_updated],
          limit: 1,
          select: %{
            id: note.id,
          }

        oldest_note = ElixirNotes.Repo.one(oldest_note_query)

        query = from note in ElixirNotes.Note,
          where: note.user_id == ^session.id and note.deleted == false and note.date_updated < ^date,
          order_by: [desc: note.date_updated],
          select: %{
            id: note.id,
            content: note.content,
            date_updated: note.date_updated
          },
          limit: 100

        data = ElixirNotes.Repo.all(query)
        response_body = %{message: "Notes fetched successfully.", data: data, oldest_note: oldest_note} |> Jason.encode!()
        conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, response_body)
      else
        latest_note_query = from note in ElixirNotes.Note,
          where: note.user_id == ^session.id and note.deleted == false,
          order_by: [desc: note.date_updated],
          limit: 1,
          select: %{
            id: note.id,
          }

        latest_note = ElixirNotes.Repo.one(latest_note_query)

        query = from note in ElixirNotes.Note,
          where: note.user_id == ^session.id and note.deleted == false and note.date_updated > ^date,
          order_by: [asc: note.date_updated],
          select: %{
            id: note.id,
            content: note.content,
            date_updated: note.date_updated
          },
          limit: 100

        data = ElixirNotes.Repo.all(query)
        data = Enum.reverse(data)
        response_body = %{message: "Notes fetched successfully.", data: data, latest_note: latest_note} |> Jason.encode!()
        conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, response_body)
      end
    else
      response_body = %{message: "Unauthorized"} |> Jason.encode!()
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, response_body)
    end
  end

  def remove_meta_from_list(structs) when is_list(structs) do
    structs
    |> Enum.map(fn struct ->
      struct
      |> Map.from_struct()
      |> Map.drop([:__meta__])
    end)
  end
end
