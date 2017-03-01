defmodule ExRss.Session.Helpers do
  import Plug.Conn

  alias ExRss.Repo
  alias ExRss.User

  def current_user(conn) do
    account = get_session(conn, :current_user)

    Repo.get(User, account.id)
  end
end