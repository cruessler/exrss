defmodule ExRss.Api.V1.FeedController do
  use ExRss.Web, :controller

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

    unread_entries = from(e in Entry, where: e.read == false)

    feeds =
      current_user
      |> assoc(:feeds)
      |> Repo.all()
      |> Repo.preload(entries: unread_entries)

    json(conn, feeds)
  end

  def discover(conn, %{"url" => url}) do
    case FeedAdder.discover_feeds(url) do
      {:ok, feeds} ->
        json(conn, feeds)

      {:error, error} ->
        Logger.info("Could not discover feeds on #{url}: #{inspect(error)}")

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
        feed = feed |> Map.take([:id, :url, :title]) |> Map.put(:entries, [])

        json(conn, feed)

      {:error, :feed, changeset, _} ->
        conn
        |> put_status(:bad_request)
        |> render(ExRss.ChangesetView, "error.json", changeset: changeset)

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
