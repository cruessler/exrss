defmodule ExRss.FeedController do
  use ExRss.Web, :controller

  alias ExRss.Feed

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
