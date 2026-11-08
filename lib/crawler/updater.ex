defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.{Feed, FeedParser, FeedUpdater, Repo}
  alias HTTPoison.{Error, Response}

  @max_feed_parser_bytes 10 * 1024 * 1024

  def update(feed, fetch \\ &fetch_url/1, opts \\ []) do
    with {:ok, %Response{body: body}} <- fetch.(feed.url),
         {:ok, raw_feed} <- Feed.parse(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction() do
      compare_with_candidate_parser? =
        Keyword.get(
          opts,
          :compare_with_candidate_parser?,
          Application.get_env(:ex_rss, :compare_with_candidate_parser?, false)
        )

      if compare_with_candidate_parser? do
        candidate_parser = Keyword.get(opts, :candidate_parser, &FeedParser.parse/1)

        try do
          compare_feeder_ex_and_feed_parser(feed, raw_feed, body, candidate_parser)
        rescue
          _ ->
            Logger.info("FeedParser failed because an exception was raised",
              title: feed.title,
              url: feed.url
            )
        catch
          kind, reason ->
            Logger.info("FeedParser failed because a something was thrown",
              title: feed.title,
              url: feed.url,
              kind: kind,
              reason: reason
            )
        end
      end

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

  defp compare_feeder_ex_and_feed_parser(feed, feeder_ex_feed, xml, candidate_parser) do
    if byte_size(xml) <= @max_feed_parser_bytes do
      Logger.info("Comparing FeederEx and FeedParser",
        title: feed.title,
        url: feed.url
      )

      case candidate_parser.(xml) do
        {:ok, feed_parser_feed} ->
          feed_parser_entries =
            Feed.parse_entries(feed, feed_parser_feed)
            |> Enum.map(&Map.drop(&1, [:raw_posted_at, :inserted_at, :updated_at]))

          feeder_ex_entries =
            Feed.parse_entries(feed, feeder_ex_feed)
            |> Enum.map(&Map.drop(&1, [:raw_posted_at, :inserted_at, :updated_at]))

          normalized_feed_parser_title = String.trim(feed_parser_feed.title)
          normalized_feeder_ex_title = String.trim(feeder_ex_feed.title)

          if normalized_feed_parser_title != normalized_feeder_ex_title or
               feed_parser_entries != feeder_ex_entries do
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

        {:error, reason} ->
          Logger.info("Feed could not be parsed with FeedParser",
            title: feed.title,
            url: feed.url,
            reason: reason
          )
      end
    else
      Logger.info("Feed was larger than 10 MiB, not comparing parsers",
        title: feed.title,
        url: feed.url
      )
    end
  end
end
