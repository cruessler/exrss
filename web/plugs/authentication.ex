defmodule ExRss.Plug.Authentication do
  import Plug.Conn
  import Phoenix.Controller

  def init(logged_out_path) do
    logged_out_path
  end

  def call(conn, logged_out_path) do
    conn
    |> authenticate(logged_out_path)
  end

  defp authenticate(conn, logged_out_path) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: logged_out_path)
      |> halt
    end
  end
end
