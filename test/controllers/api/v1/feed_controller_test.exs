defmodule ExRss.Api.V1.FeedControllerTest do
  use ExRss.ConnCase

  alias ExRss.User

  setup do
    user = Repo.insert!(%User{email: "jane@doe.com"})

    feed =
      user
      |> Ecto.build_assoc(:feeds, %{title: "Title", url: "http://example.com"})
      |> Repo.insert!()

    entry =
      feed
      |> Ecto.build_assoc(
        :entries,
        %{
          url: "http://example.com/1",
          title: "Title",
          raw_posted_at: "Sun, 21 Dec 2014 16:08:00 +0100",
          read: false,
          feed_id: 1
        }
      )
      |> Repo.insert!()

    %{user: user, feed: feed, entry: entry}
  end

  test "GET /feeds", %{conn: conn, user: user, entry: %{id: entry_id}} do
    conn =
      conn
      |> with_authorization(user)
      |> get("/api/v1/feeds")

    response = json_response(conn, 200)
    assert [%{"entries" => [%{"id" => ^entry_id}]}] = response
  end

  test "GET /feeds/only_unread_entries", %{conn: conn, user: user, feed: feed} do
    feed
    |> Ecto.build_assoc(
      :entries,
      %{
        url: "http://example.com/2",
        title: "Title 2",
        raw_posted_at: "Sun, 22 Dec 2014 16:08:00 +0100",
        read: true,
        feed_id: 1
      }
    )
    |> Repo.insert!()

    feed
    |> Ecto.build_assoc(
      :entries,
      %{
        url: "http://example.com/3",
        title: "Title 3",
        raw_posted_at: "Sun, 29 Dec 2014 16:08:00 +0100",
        read: true,
        feed_id: 1
      }
    )
    |> Repo.insert!()

    conn =
      conn
      |> with_authorization(user)
      |> get("/api/v1/feeds/only_unread_entries")

    response = json_response(conn, 200)

    assert [
             %{
               "entries" => [%{"url" => "http://example.com/1"}],
               "unread_entries_count" => 1,
               "read_entries_count" => 2
             }
           ] = response
  end

  test "POST /feeds returns new feed on success", %{conn: conn, user: user} do
    conn =
      conn
      |> with_authorization(user)
      |> post("/api/v1/feeds", feed: [title: "Title", url: "http://www.example.com"])

    response = json_response(conn, 200)
    assert %{"id" => _, "title" => "Title", "entries" => []} = response
  end

  test "POST /feeds returns errors on failure", %{conn: conn, user: user} do
    conn =
      conn
      |> with_authorization(user)
      |> post("/api/v1/feeds", feed: [title: "", url: ""])

    response = json_response(conn, 400)
    assert %{"errors" => %{"title" => _, "url" => _}} = response
  end

  test "PATCH /feeds/1 marks entries as read", %{
    conn: conn,
    user: user,
    feed: %{id: feed_id},
    entry: %{id: entry_id, url: entry_url, read: false}
  } do
    conn =
      conn
      |> with_authorization(user)
      |> patch("/api/v1/feeds/#{feed_id}", feed: [read: true])

    response = json_response(conn, 200)

    assert %{
             "entries" => [
               %{
                 "id" => ^entry_id,
                 "posted_at" => nil,
                 "read" => true,
                 "title" => "Title",
                 "url" => ^entry_url
               }
             ],
             "id" => ^feed_id,
             "title" => "Title",
             "url" => "http://example.com"
           } = response
  end

  test "DELETE /feeds/1 succeeds", %{conn: conn, user: user, feed: feed} do
    conn =
      conn
      |> with_authorization(user)
      |> delete("/api/v1/feeds/#{feed.id}")

    json_response(conn, 200)
  end

  test "DELETE /feeds/2 raises error for non-existing feed", %{conn: conn, user: user} do
    assert_raise Ecto.NoResultsError, fn ->
      conn
      |> with_authorization(user)
      |> delete("/api/v1/feeds/2")
    end
  end
end
