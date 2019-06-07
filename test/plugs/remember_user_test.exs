defmodule ExRss.RememberUser do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ecto.Changeset

  alias ExRss.Repo
  alias ExRss.{Session, User}
  alias ExRss.Plug.RememberUser

  @user %User{id: 1}

  @plug RememberUser.init(nil)

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    Repo.insert!(%User{id: 1, email: "jane@doe.com"})

    :ok
  end

  test "Plug.RememberUser" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> assign(:current_user, nil)
      |> RememberUser.call(@plug)

    assert is_nil(get_session(conn, :current_user))

    user = User.renew_remember_me_token(@user) |> Changeset.apply_changes()

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> Plug.Conn.fetch_cookies()
      |> put_session(:current_user, user)
      |> Session.renew_remember_me_cookie()

    assert ^user = get_session(conn, :current_user)

    new_conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> Plug.Test.recycle_cookies(conn)
      |> Plug.Conn.fetch_cookies()

    assert is_nil(get_session(new_conn, :current_user))

    new_conn =
      new_conn
      |> RememberUser.call(@plug)

    assert %User{id: 1, remember_me_token: remember_me_token} =
             get_session(new_conn, :current_user)

    assert is_binary(remember_me_token)
  end
end
