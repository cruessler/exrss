defmodule ExRss.Api.V1.FeedController do
  use ExRss.Web, :controller

  alias ExRss.Feed
  alias ExRss.FeedAdder
  alias ExRss.User

  def discover(conn, %{"url" => url}) do
    case FeedAdder.discover_feeds(url) do
      {:ok, feeds} ->
        json(conn, feeds)

      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt()
    end
  end

  def create(conn, %{"feed" => feed_params}) do
    changeset =
      Repo.get!(User, conn.assigns.current_account.id)
      |> build_assoc(:feeds)
      |> Feed.changeset(feed_params)

    case Repo.insert(changeset) do
      {:ok, feed} ->
        json(conn, Map.take(feed, [:id, :url, :title]))

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render(ExRss.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
