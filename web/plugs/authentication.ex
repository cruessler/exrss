defmodule ExRss.Plug.Authentication do
  import Plug.Conn
  import Phoenix.Controller

  alias ExRss.Repo
  alias ExRss.User

  def init(logged_out_path) do
    logged_out_path
  end

  def call(conn, logged_out_path) do
    conn
    |> authenticate(logged_out_path)
  end

  defp authenticate(conn, logged_out_path) do
    with %User{id: id} <- get_session(conn, :current_user),
         user = Repo.get(User, id) do
      conn
      |> assign(:current_user, user)
    else
      _ ->
        conn
        |> redirect(to: logged_out_path)
        |> halt
    end
  end
end
