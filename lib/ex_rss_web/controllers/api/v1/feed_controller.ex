defmodule ExRssWeb.Api.V1.FeedController do
  use ExRssWeb, :controller

  require Logger

  alias ExRss.{Entry, Feed, User}
  alias ExRss.{FeedAdder, FeedRemover}

  def index(conn, _) do
    current_user = Repo.get!(User, conn.assigns.current_account.id)

    feeds =
      current_user
      |> assoc(:feeds)
      |> Repo.all()
      |> Repo.preload(:entries)

    json(conn, feeds)
  end

  def only_unread_entries(conn, _) do
    current_user = Repo.get!(User, conn.assigns.current_account.id)

    feeds_of_current_user = current_user |> assoc(:feeds)

    unread_entries =
      from(
        e in Entry,
        where: e.read == false
      )

    feeds_with_counts =
      from(
        f in feeds_of_current_user,
        join: e in Entry,
        on: f.id == e.feed_id,
        group_by: f.id,
        select: %{
          f
          | unread_entries_count: filter(count(e.id), e.read == false),
            read_entries_count: filter(count(e.id), e.read == true),
            has_error: f.retries > 0
        }
      )

    feeds =
      feeds_with_counts
      |> Repo.all()
      |> Repo.preload(entries: unread_entries)

    json(conn, feeds)
  end

  def discover(conn, %{"url" => url}) do
    case FeedAdder.discover_feeds(url) do
      {:ok, feeds} ->
        json(conn, feeds)

      {:error, error} ->
        Logger.error("Could not discover feeds", url: url, error: error)

        conn
        |> resp(:bad_request, "")
        |> halt()
    end
  end

  def create(conn, %{"feed" => feed_params}) do
    multi =
      Repo.get!(User, conn.assigns.current_account.id)
      |> FeedAdder.add_feed(feed_params)

    case Repo.transaction(multi) do
      {:ok, %{feed: feed}} ->
        feed =
          feed
          # This has to be manually kept in sync with `Types.Feed.decodeFeed`
          # as long as there is no automated process.
          |> Map.take([:id, :url, :title, :last_successful_update_at])
          |> Map.put(:has_error, false)
          |> Map.put(:entries, [])

        json(conn, feed)

      {:error, :feed, changeset, _} ->
        conn
        |> put_status(:bad_request)
        |> put_view(ExRssWeb.ChangesetView)
        |> render("error.json", changeset: changeset)

      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt()
    end
  end

  def update(conn, %{"id" => id, "feed" => %{"read" => true}}) do
    changeset =
      Repo.get!(User, conn.assigns.current_account.id)
      |> assoc(:feeds)
      |> Repo.get!(id)
      |> Repo.preload(:entries)
      |> Feed.mark_as_read()

    case Repo.update(changeset) do
      {:ok, feed} ->
        json(conn, feed)

      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt
    end
  end

  def update(conn, %{"id" => id, "feed" => feed_params}) do
    changeset =
      Repo.get!(User, conn.assigns.current_account.id)
      |> assoc(:feeds)
      |> Repo.get!(id)
      |> Repo.preload(:entries)
      |> Feed.api_changeset(feed_params)

    case Repo.update(changeset) do
      {:ok, feed} ->
        json(conn, feed)

      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt
    end
  end

  def update(conn, _) do
    conn
    |> resp(:bad_request, "")
    |> halt
  end

  def delete(conn, feed_params) do
    multi =
      Repo.get!(User, conn.assigns.current_account.id)
      |> FeedRemover.remove_feed(feed_params)

    case Repo.transaction(multi) do
      {:ok, %{feed: _}} ->
        json(conn, nil)

      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt()
    end
  end
end
