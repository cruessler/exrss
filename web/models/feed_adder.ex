defmodule ExRss.FeedAdder do
  import Ecto
  import Ecto.Changeset

  alias Ecto.Multi
  alias ExRss.Feed

  def add_feed(user, feed_params) do
    changeset =
      user
      |> build_assoc(:feeds)
      |> Feed.changeset(feed_params)
      |> put_change(:next_update_at, DateTime.utc_now)

    Multi.new
    |> Multi.insert(:feed, changeset)
    |> Multi.run(:notify_queue, fn
      %{feed: feed} ->
        GenServer.cast(ExRss.Crawler.Queue, {:add_feed, feed})

        {:ok, nil}
      end)
  end

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
