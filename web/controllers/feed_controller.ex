defmodule ExRss.FeedController do
  use ExRss.Web, :controller

  alias ExRss.Feed

  def index(conn, _params) do
    feeds =
      conn.assigns.current_user
      |> assoc(:feeds)
      |> Repo.all()
      |> Repo.preload(:entries)

    conn
    |> assign(:feeds, feeds)
    |> render("index.html")
  end
end
