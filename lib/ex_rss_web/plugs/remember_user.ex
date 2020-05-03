defmodule ExRssWeb.Plug.RememberUser do
  import Plug.Conn

  alias ExRss.Repo
  alias ExRss.Session
  alias ExRss.User

  def init(_) do
  end

  def call(conn, _) do
    with nil <- get_session(conn, :current_user),
         {:ok, token} <- Session.fetch_remember_me_cookie(conn),
         {:ok, user} <- User.verify_remember_me_token(token),
         {:ok, user} <- User.renew_remember_me_token(user) |> Repo.update() do
      conn
      |> put_session(:current_user, user)
      |> Session.renew_remember_me_cookie()
    else
      _ ->
        conn
    end
  end
end
