defmodule ExRssWeb.Api.V1.EntryControllerTest do
  use ExRssWeb.ConnCase

  alias ExRss.Entry
  alias ExRss.{Feed, User}
  alias ExRss.User.Account

  @salt "user"

  setup do
    Repo.insert!(%User{id: 1, email: "jane@doe.com"})
    Repo.insert!(%Feed{id: 1, user_id: 1, title: "Title", url: "http://example.com"})

    Repo.insert!(%Entry{
      id: 1,
      url: "http://example.com/1",
      title: "Title",
      raw_posted_at: "Sun, 21 Dec 2014 16:08:00 +0100",
      read: false,
      feed_id: 1
    })

    Repo.insert!(%Entry{
      id: 2,
      url: "http://example.com/2",
      title: nil,
      raw_posted_at: "Sun, 21 Dec 2014 16:09:00 +0100",
      read: false,
      feed_id: 1
    })

    account = Repo.get!(Account, 1)
    first = Repo.get!(Entry, 1)
    second = Repo.get!(Entry, 2)

    {:ok, %{account: account, first: first, second: second}}
  end

  test "PUT /entries/1", %{account: account, first: %{id: id}} do
    conn = build_conn()

    token = Phoenix.Token.sign(ExRssWeb.Endpoint, @salt, account)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/entries/#{id}", %{"id" => id, "entry" => %{"read" => true}})

    json = json_response(conn, 200)
    assert %{"id" => ^id, "read" => true} = json
  end

  test "PATCH /entries/2", %{account: account, second: %{id: id}} do
    conn = build_conn()

    token = Phoenix.Token.sign(ExRssWeb.Endpoint, @salt, account)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> patch("/api/v1/entries/#{id}", %{"entry" => %{"read" => true}})

    json = json_response(conn, 200)
    assert %{"id" => ^id, "read" => true} = json
  end
end
