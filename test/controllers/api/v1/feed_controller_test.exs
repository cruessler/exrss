defmodule ExRss.Api.V1.FeedControllerTest do
  use ExRss.ConnCase

  alias ExRss.{Entry, Feed, User}

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

    :ok
  end

  test "POST /feeds returns new feed on success", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> post("/api/v1/feeds", feed: [title: "Title", url: "http://www.example.com"])

    response = json_response(conn, 200)
    assert %{"id" => _, "title" => "Title"} = response
  end

  test "POST /feeds returns errors on failure", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> post("/api/v1/feeds", feed: [title: "", url: ""])

    response = json_response(conn, 400)
    assert %{"errors" => %{"title" => _, "url" => _}} = response
  end

  test "PATCH /feeds/1 marks entries as read", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> patch("/api/v1/feeds/1", feed: [read: true])

    response = json_response(conn, 200)

    assert %{
             "entries" => [
               %{
                 "id" => 1,
                 "posted_at" => nil,
                 "read" => true,
                 "title" => "Title",
                 "url" => "http://example.com/1"
               }
             ],
             "id" => 1,
             "title" => "Title",
             "url" => "http://example.com"
           } = response
  end

  test "DELETE /feeds/1 succeeds", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> delete("/api/v1/feeds/1")

    json_response(conn, 200)
  end

  test "DELETE /feeds/2 raises error for non-existing feed", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      conn
      |> with_authorization
      |> delete("/api/v1/feeds/2")
    end
  end
end
