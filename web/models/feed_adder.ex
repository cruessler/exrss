defmodule ExRss.FeedAdder do
  def discover_feeds(url) do
    with {:ok, response} <- HTTPoison.get(url, [], follow_redirect: true),
         200 <- response.status_code,
         html <- Floki.parse(response.body)
    do
      {:ok, extract_feeds(html)}
    else
      i when is_integer(i) -> {:error, :wrong_status_code}
      x -> x
    end
  end

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
