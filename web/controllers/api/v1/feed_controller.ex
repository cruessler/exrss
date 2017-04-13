defmodule ExRss.Api.V1.FeedController do
  use ExRss.Web, :controller

  alias ExRss.FeedAdder

  def discover(conn, %{"url" => url}) do
    with uri = URI.parse(url),
         %URI{authority: authority} when not is_nil(authority) <- uri,
         {:ok, feeds} <- FeedAdder.discover_feeds(url)
    do
      feeds = Enum.map(feeds, fn f ->
        Map.put(f, :url, URI.merge(uri, f.href) |> to_string)
      end)

      json(conn, feeds)
    else
      _ ->
        conn
        |> resp(:bad_request, "")
        |> halt()
    end
  end
end
