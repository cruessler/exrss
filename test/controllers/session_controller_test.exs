defmodule ExRss.SessionControllerTest do
  use ExRss.ConnCase

  alias ExRss.User.Registration

  @password "password"
  @email "john@doe.com"

  test "GET /session/new", %{conn: conn} do
    conn = get(conn, "/session/new")

    assert html_response(conn, 200) =~ "Log in"
  end

  test "POST /session", %{conn: conn} do
    params = %{email: @email, password: @password, password_confirmation: @password}

    {:ok, _} =
      Registration.changeset(%Registration{}, params)
      |> Repo.insert()

    params = %{session: %{email: @email, password: @password}}

    conn = post(conn, "/session", params)

    assert html_response(conn, 302)
    assert %{remember_me_token: remember_me_token} = get_session(conn, :current_user)
    assert is_binary(remember_me_token)
  end

  test "DELETE /session", %{conn: conn} do
    conn = delete(conn, "/session")

    assert html_response(conn, 302)
  end
end
