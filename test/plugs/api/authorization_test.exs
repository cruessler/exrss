defmodule ExRss.Api.AuthorizationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExRss.Plug.Api.Authorization
  alias ExRss.User

  @salt "user"
  @plug Authorization.init(@salt)
  @user %User{id: 1}

  test "sets current_user when a valid token is supplied" do
    conn =
      conn(:get, "/")

    token = Phoenix.Token.sign(ExRss.Endpoint, @salt, @user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> Authorization.call(@plug)

    assert conn.status != 401
    assert @user = conn.assigns.current_user
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
