defmodule ExRss.FeedAdder do
  require Logger

  import Ecto
  import Ecto.Changeset

  alias Ecto.Multi
  alias ExRss.Entry
  alias ExRss.Feed
  alias HTTPoison.Response

  @no_title "feed does not have a title"

  def add_feed(user, feed_params) do
    changeset =
      user
      |> build_assoc(:feeds)
      |> Feed.changeset(feed_params)
      |> put_change(:retries, 0)
      |> put_change(:next_update_at, DateTime.utc_now())

    Multi.new()
    |> Multi.insert(:feed, changeset)
    |> Multi.run(:notify_queue, fn _repo, %{feed: feed} ->
      GenServer.cast(ExRss.Crawler.Queue, {:add_feed, feed})

      {:ok, nil}
    end)
  end

  def discover_feed(url) do
    with uri = URI.parse(url),
         %URI{authority: authority} when not is_nil(authority) <- uri,
         {:ok, response} <- HTTPoison.get(uri, [], follow_redirect: true),
         200 <- response.status_code,
         {:ok, raw_feed} <- Feed.parse(response.body) do
      candidate = extract_candidate(raw_feed)

      {:ok, candidate}
    else
      i when is_integer(i) ->
        {:error, :wrong_status_code}

      %URI{} ->
        {:error, :uri_not_absolute}

      x ->
        x
    end
  end

  def discover_feeds(url) do
    with uri = URI.parse(url),
         %URI{authority: authority} when not is_nil(authority) <- uri,
         {:ok, response} <- HTTPoison.get(uri, [], follow_redirect: true),
         200 <- response.status_code,
         html <- Floki.parse(response.body) do
      feeds =
        for f <- extract_feeds(html) do
          Map.put(f, :url, URI.merge(uri, f.href) |> to_string)
          |> add_frequency_info
        end

      {:ok, feeds}
    else
      i when is_integer(i) ->
        {:error, :wrong_status_code}

      %URI{} ->
        {:error, :uri_not_absolute}

      x ->
        x
    end
  end

  def extract_feeds(html) do
    (rss_feeds(html) ++ atom_feeds(html))
    |> Enum.map(&extract_feed/1)
    |> Enum.reject(&is_nil/1)
  end

  def extract_candidate(feed) do
    feed
    |> Map.put(:href, feed.url)
    |> Map.put(:frequency, extract_frequency_info(feed))
    |> Map.take([:url, :title, :href, :frequency])
  end

  def extract_feed(feed) do
    case Floki.attribute(feed, "href") do
      [href] ->
        title = extract_title(feed)

        %{title: title, href: href}

      [] ->
        nil
    end
  end

  def extract_title(feed) do
    case Floki.attribute(feed, "title") do
      [title] ->
        title

      [] ->
        @no_title
    end
  end

  def rss_feeds(html) do
    html
    |> Floki.find("link[rel=alternate][type='application/rss+xml']")
  end

  def atom_feeds(html) do
    html
    |> Floki.find("link[rel=alternate][type='application/atom+xml']")
  end

  def add_frequency_info(feed) do
    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url, [], follow_redirect: true),
         {:ok, raw_feed} <- Feed.parse(body) do
      Map.put(feed, :frequency, extract_frequency_info(raw_feed))
    else
      {:error, error} ->
        Logger.info("Could not add frequency info for #{feed.url}: #{inspect(error)}")

        Map.put(feed, :frequency, nil)
    end
  end

  @doc """
  Calculates the frequency of posts for a given feed. Returns the number of
  posts that have been published as well as the number of seconds between the
  publication of the first and the last post.

    iex> FeedAdder.extraxt_frequency_info(feed)
    %{posts: 3, seconds: 97362}
  """
  def extract_frequency_info(raw_feed) do
    entries =
      raw_feed.entries
      |> Enum.flat_map(fn e ->
        case Entry.parse_time(e.updated) do
          {:ok, posted_at} -> [posted_at]
          _ -> []
        end
      end)

    try do
      {min_date, max_date} = Enum.min_max_by(entries, &Timex.to_gregorian_microseconds/1)

      %{posts: Enum.count(entries), seconds: Timex.diff(max_date, min_date, :seconds)}
    rescue
      Enum.EmptyError -> nil
    end
  end
end
