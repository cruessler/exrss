defmodule ExRssWeb.FeedController do
  use ExRssWeb, :controller

  alias ExRss.FeedAdder

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def new(conn, %{"url" => url}) do
    candidate =
      case FeedAdder.discover_feed(url) do
        {:ok, candidate} -> candidate
        _ -> nil
      end

    conn
    |> assign(:url, url)
    |> assign(:candidate, candidate)
    |> render("new.html")
  end
end
