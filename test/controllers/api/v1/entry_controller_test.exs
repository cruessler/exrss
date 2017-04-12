defmodule ExRss.Api.V1.EntryControllerTest do
  use ExRss.ConnCase

  alias ExRss.Entry
  alias ExRss.User.Account

  @salt "user"

  setup do
    account = Repo.get!(Account, 1)
    entry = Repo.get!(Entry, 1)

    {:ok, %{account: account, entry: entry}}
  end

  test "PUT /entries/1", %{account: account, entry: %{id: id}} do
    conn = build_conn()

    token = Phoenix.Token.sign(ExRss.Endpoint, @salt, account)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/entries/#{id}", %{"id" => id, "entry" => %{"read" => true}})

    json = json_response(conn, 200)
    assert %{"id" => ^id, "read" => true} = json
  end
end
