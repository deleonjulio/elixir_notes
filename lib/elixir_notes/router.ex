defmodule ElixirNotes.Router do
  use Plug.Router

  # Please generate your own secret_key_base
  @secret_key_base "N9dxzD+7oS03oEyv91LiWgAGi6/kh5O11syicdpMigUPhKVl6WxlBw/Pwy9Q9S0aXFphnsSUB4mLvBDNepVbMQ=="

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(Corsica, origins: "http://localhost:5173", allow_headers: ["content-type"], allow_credentials: true)
  plug Plug.Session, store: :cookie,
    key: "_my_app_session",
    encryption_salt: "cookie store encryption salt",
    signing_salt: "cookie store signing salt",
    # max_age: 10, in seconds
    log: :debug
  plug :put_secret_key_base
  plug :fetch_session
  plug(:match)
  plug(:dispatch)

  defp put_secret_key_base(conn, _opts) do
    put_in(conn.secret_key_base, Base.encode64(@secret_key_base))
  end

  def child_spec(_opts) do
    Plug.Cowboy.child_spec(
      scheme: :http,
      options: [port: 8080],
      plug: __MODULE__
    )
  end

  get "/isAuthenticated" do
    ElixirNotes.Authentication.is_authenticated(conn)
  end

  post "/login" do
    ElixirNotes.Authentication.login(conn)
  end

  post "/logout" do
    ElixirNotes.Authentication.logout(conn)
  end

  post "/register" do
    ElixirNotes.Authentication.register(conn)
  end

  post "/note" do
    ElixirNotes.Note.create(conn)
  end

  put "/note" do
    ElixirNotes.Note.update_note(conn)
  end

  delete "/note/:id" do
    ElixirNotes.Note.delete(conn)
  end

  get "/getNotes" do
    ElixirNotes.Note.get(conn)
  end

  get "/note" do
    ElixirNotes.Note.search(conn)
  end

  post "/preloadNotes" do
    ElixirNotes.Note.preload_notes(conn)
  end

  post "/loadMoreNotes" do
    ElixirNotes.Note.load_more_notes(conn)
  end

  match _ do
    response_body = %{error: "Page not found."} |> Jason.encode!()
    conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(404, response_body)
  end
end
