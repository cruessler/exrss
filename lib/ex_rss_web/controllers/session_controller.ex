defmodule ExRssWeb.SessionController do
  use ExRss.Web, :controller

  alias ExRss.Session
  alias ExRss.User

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => session_params}) do
    with {:ok, user} <- Session.login(session_params),
         {:ok, user} <- User.renew_remember_me_token(user) |> Repo.update() do
      conn
      |> put_session(:current_user, user)
      |> Session.renew_remember_me_cookie()
      |> put_flash(:info, "You are now logged in.")
      |> redirect(to: Routes.feed_path(conn, :index))
    else
      :error ->
        conn
        |> put_flash(:error, "You supplied a wrong email or password.")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "You are now logged out.")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
