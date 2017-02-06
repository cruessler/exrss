defmodule ExRss.UserControllerTest do
  use ExRss.ConnCase

  test "POST /users", %{conn: conn} do
    params =
      [registration:
        [name: "New user",
         email: "new@us.er",
         password: "password",
         password_confirmation: "password"]]

    conn = post conn, "/users", params

    assert html_response(conn, 302)
  end

  test "POST /users with confirmation not matching password", %{conn: conn} do
    params =
      [registration:
        [name: "New user",
         email: "new@us.er",
         password: "password",
         password_confirmation: ""]]

    conn = post conn, "/users", params

    assert html_response(conn, 200)
  end
end
