defmodule ExRssWeb.AuthenticationTest do
  use ExUnit.Case, async: true

  alias ExRssWeb.Plug.Authentication
  alias ExRss.Repo
  alias ExRss.User

  import Plug.Test

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  @plug Authentication.init("/")

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Repo.insert!(%User{id: 1, email: "jane@doe.com"})

    :ok
  end

  test "Plug.Authentication" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> Authentication.call(@plug)

    assert conn.status == 302

    session = Map.put(@session, :current_user, %User{id: 0})

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(session)
      |> Authentication.call(@plug)

    assert conn.status != 302

    user = Repo.get!(User, 1)
    session = Map.put(@session, :current_user, user)

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(session)
      |> Authentication.call(@plug)

    assert user == conn.assigns.current_user
  end
end
