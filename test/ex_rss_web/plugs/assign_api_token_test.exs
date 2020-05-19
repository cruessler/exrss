defmodule ExRssWeb.AssignApiToken do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExRss.User
  alias ExRss.User.Account
  alias ExRssWeb.Plug.AssignApiToken

  @salt "user"
  @user %User{id: 1}

  @plug AssignApiToken.init(@salt)

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  # 1 day
  @max_age 86_400

  test "Plug.AssignApiToken" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> assign(:current_user, @user)
      |> AssignApiToken.call(@plug)

    assert {:ok, %Account{id: 1}} =
             Phoenix.Token.verify(
               ExRssWeb.Endpoint,
               @salt,
               conn.assigns.api_token,
               max_age: @max_age
             )
  end
end
