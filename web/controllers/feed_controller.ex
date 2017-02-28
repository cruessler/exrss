defmodule ExRss.FeedController do
  use ExRss.Web, :controller

  alias ExRss.Feed

  def index(conn, _params) do
    feeds =
      current_user(conn)
      |> assoc(:feeds)
      |> Repo.all
      |> Repo.preload(:entries)

    conn
    |> assign(:feeds, feeds)
    |> render("index.html")
  end
end
