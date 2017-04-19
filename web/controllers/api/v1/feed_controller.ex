defmodule ExRss.Api.V1.FeedController do
  use ExRss.Web, :controller

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
end
