defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.{Feed, FeedParser, FeedUpdater, Repo}
  alias HTTPoison.{Error, Response}

  @max_feed_parser_bytes 10 * 1024 * 1024

  def update(feed, fetch \\ &fetch_url/1) do
    with {:ok, %Response{body: body}} <- fetch.(feed.url),
         {:ok, raw_feed} <- Feed.parse(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction() do
      compare_feeder_ex_and_feed_parser(feed, raw_feed, body)

      {:ok, new_feed}
    else
      {:error, %Error{reason: reason}} ->
        {:error, reason}

      {:error, error} ->
        {:error, error}

      {:error, failed_operation, _, _} ->
        {:error, "error at step #{failed_operation}"}
    end
  end

  defp fetch_url(url) do
    HTTPoison.get(url, [], follow_redirect: true)
  end

  defp compare_feeder_ex_and_feed_parser(feed, feeder_ex_feed, xml) do
    if System.get_env("EXRSS_COMPARE_WITH_FEED_PARSER") == "1" and
         byte_size(xml) <= @max_feed_parser_bytes do
      Logger.info("Comparing FeederEx and FeedParser",
        title: feed.title,
        url: feed.url
      )

      case FeedParser.parse(xml) do
        {:ok, feed_parser_feed} ->
          feed_parser_entries =
            Feed.parse_entries(feed, feed_parser_feed)
            |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

          feeder_ex_entries =
            Feed.parse_entries(feed, feeder_ex_feed)
            |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

          if feed_parser_entries != feeder_ex_entries do
            Logger.info("Mismatch between FeederEx and FeedParser detected",
              title: feed.title,
              url: feed.url
            )
          else
            Logger.info("FeederEx and FeedParser agree",
              title: feed.title,
              url: feed.url
            )
          end

        _ ->
          Logger.info("Feed could not be parsed with FeedParser",
            title: feed.title,
            url: feed.url
          )
      end
    end
  end
end
