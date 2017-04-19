defmodule ExRss.FeedAdder do
  def discover_feeds(url) do
    with uri = URI.parse(url),
         %URI{authority: authority} when not is_nil(authority) <- uri,
         {:ok, response} <- HTTPoison.get(uri, [], follow_redirect: true),
         200 <- response.status_code,
         html <- Floki.parse(response.body)
    do
      feeds =
        for f <- extract_feeds(html) do
          Map.put(f, :url, URI.merge(uri, f.href) |> to_string)
        end

      {:ok, feeds}
    else
      i when is_integer(i) ->
        {:error, :wrong_status_code}

      %URI{} ->
        {:error, :uri_not_absolute}

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
