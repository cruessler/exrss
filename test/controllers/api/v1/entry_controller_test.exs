defmodule ExRss.Api.V1.EntryControllerTest do
  use ExRss.ConnCase

  alias ExRss.Entry
  alias ExRss.User

  @salt "user"

  setup do
    user = Repo.get!(User, 1)
    entry = Repo.get!(Entry, 1)

    {:ok, %{user: user, entry: entry}}
  end

  test "PUT /entries/1", %{user: user, entry: %{id: id}} do
    conn = build_conn()

    token = Phoenix.Token.sign(ExRss.Endpoint, @salt, user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/entries/#{id}", %{"id" => id, "entry" => %{"read" => true}})

    json = json_response(conn, 200)
    assert %{"id" => ^id, "read" => true} = json
  end
end
