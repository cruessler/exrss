defmodule ExRss.Api.V1.FeedController do
  use ExRss.Web, :controller

  alias ExRss.{Entry, Feed, User}
  alias ExRss.FeedAdder

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
    multi =
      Repo.get!(User, conn.assigns.current_account.id)
      |> FeedAdder.add_feed(feed_params)

    case Repo.transaction(multi) do
      {:ok, %{feed: feed}} ->
        json(conn, Map.take(feed, [:id, :url, :title]))

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

  def delete(conn, %{"id" => feed_id}) do
    User
    |> Repo.get!(conn.assigns.current_account.id)
    |> Ecto.assoc(:feeds)
    |> Repo.get!(feed_id)
    |> Repo.delete!()

    json(conn, nil)
  end
end
