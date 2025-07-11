defmodule ExRssWeb.Api.AuthorizationTest do
  use ExUnit.Case, async: true

  alias ExRss.User.Account
  alias ExRssWeb.Plug.Api.Authorization

  import Plug.Test
  import Plug.Conn

  @salt "user"
  @plug Authorization.init(@salt)
  @account %Account{id: 1}

  test "sets current_user when a valid token is supplied" do
    conn = conn(:get, "/")

    token = Phoenix.Token.sign(ExRssWeb.Endpoint, @salt, @account)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> Authorization.call(@plug)

    assert conn.status != 401
    assert @account = conn.assigns.current_account
  end

  test "replies with 401 when no token is supplied" do
    conn =
      conn(:get, "/")
      |> Authorization.call(@plug)

    refute Map.has_key?(conn.assigns, :current_user)
    assert conn.status == 401
  end

  test "replies with 401 when an invalid token is supplied" do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer nonsense")
      |> Authorization.call(@plug)

    refute Map.has_key?(conn.assigns, :current_user)
    assert conn.status == 401
  end
end
