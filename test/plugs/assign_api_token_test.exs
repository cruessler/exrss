defmodule ExRss.AssignApiToken do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExRss.User
  alias ExRss.User.Account
  alias ExRss.Plug.AssignApiToken

  @salt "user"
  @user %User{id: 1}

  @plug AssignApiToken.init(@salt)

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  test "Plug.AssignApiToken" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> assign(:current_user, @user)
      |> AssignApiToken.call(@plug)

    assert {:ok, %Account{id: 1}} =
             Phoenix.Token.verify(ExRss.Endpoint, @salt, conn.assigns.api_token)
  end
end
