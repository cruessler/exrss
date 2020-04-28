defmodule ExRss.Session do
  import Plug.Conn

  alias ExRss.Repo
  alias ExRss.User

  @remember_me_cookie "_ex_rss_remember_me_token"

  def login(params) do
    user = Repo.get_by(User, email: String.downcase(params["email"]))

    case authenticate(user, params["password"]) do
      true -> {:ok, user}
      _ -> :error
    end
  end

  def renew_remember_me_cookie(conn) do
    with %{remember_me_token: remember_me_token} <- get_session(conn, :current_user) do
      conn
      |> put_resp_cookie(@remember_me_cookie, remember_me_token)
    else
      _ ->
        conn
    end
  end

  def fetch_remember_me_cookie(conn) do
    case conn.cookies do
      %{@remember_me_cookie => token} ->
        {:ok, token}

      _ ->
        :error
    end
  end

  defp authenticate(user, password) do
    case user do
      nil -> false
      _ -> Bcrypt.verify_pass(password, user.hashed_password)
    end
  end
end
