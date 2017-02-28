defmodule ExRss.SessionController do
  use ExRss.Web, :controller

  alias ExRss.Session

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => session_params}) do
    case Session.login(session_params) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, user)
        |> put_flash(:info, "You are now logged in.")
        |> redirect(to: feed_path(conn, :index))

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
    |> redirect(to: page_path(conn, :index))
  end
end
