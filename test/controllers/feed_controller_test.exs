defmodule ExRss.FeedControllerTest do
  use ExRss.ConnCase

  alias ExRss.User
  alias ExRss.User.Registration

  @password "password"
  @email "john@doe.com"

  setup do
    Repo.insert!(%User{email: "jane@doe.com"})

    params = %{email: @email, password: @password, password_confirmation: @password}

    {:ok, _} =
      Registration.changeset(%Registration{}, params)
      |> Repo.insert()

    %{email: @email, password: @password}
  end

  test "GET /feeds", %{conn: conn, email: email, password: password} do
    params = %{session: %{email: email, password: password}}

    conn = post(conn, "/session", params)

    conn = get(conn, "/feeds")

    response = html_response(conn, 200)

    assert response =~ "Hello ExRss!"
    assert response =~ "data-elm-module=\"App.Feeds\""
  end
end
