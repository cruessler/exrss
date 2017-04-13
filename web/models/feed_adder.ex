defmodule ExRss.FeedAdder do
  def extract_feeds(html) do
    html
    |> Floki.find("link[rel=alternate][type='application/rss+xml']")
    |> Enum.map(fn feed ->
      with [title] <- Floki.attribute(feed, "title"),
           [href] <- Floki.attribute(feed, "href")
      do
        %{title: title, href: href}
      else
        [] -> nil
      end
    end)
    |> Enum.reject(&is_nil(&1))
  end
end
