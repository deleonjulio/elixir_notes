defmodule ElixirNotes.Authentication do

  def is_authenticated(conn) do
    session = Plug.Conn.get_session(conn, :user)
    authenticated = if session, do: true, else: false
    if authenticated do
      response_body = %{user: session} |> Jason.encode!()
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

  def login(conn) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, email} = Map.fetch(conn.body_params, "email")
    {:ok, password} = Map.fetch(conn.body_params, "password")

    user = %ElixirNotes.User{}
    changeset = ElixirNotes.User.login_changeset(user, %{email: email, password: password})

    if changeset.valid? do
      user = ElixirNotes.User.authenticate?(email, password)
      authenticated = if user, do: true, else: false
      if authenticated do
        response_body = %{message: "Login successful."} |> Jason.encode!()
        conn
          |> Plug.Conn.put_session(:user, %{id: user.id, email: user.email})
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, response_body)
      else
        response_body = %{message: "Email or password is incorrect."} |> Jason.encode!()
        conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(401, response_body)
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
  end

  def register(conn) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, name} = Map.fetch(conn.body_params, "name")
    {:ok, email} = Map.fetch(conn.body_params, "email")
    {:ok, password} = Map.fetch(conn.body_params, "password")

    user = %ElixirNotes.User{}
    changeset = ElixirNotes.User.changeset(user, %{name: name, email: email, password: password})

    if changeset.valid? do
      email_exist = ElixirNotes.User.email_exists?(email)
      if email_exist do
        response_body = %{message: "Email already exists."} |> Jason.encode!()
        conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(409, response_body)
      else
        case ElixirNotes.Repo.insert(changeset) do
          {:ok, _} ->
            response_body = %{message: "Registration successful."} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)
          {:error, _} ->
            response_body = %{error: "Something went wrong."} |> Jason.encode!()
            conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, response_body)
        end
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
  end

  def logout(conn) do
    conn = Plug.Conn.delete_session(conn, :user)
    response_body = %{message: "Logout successful."} |> Jason.encode!()
    conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, response_body)
  end
end
