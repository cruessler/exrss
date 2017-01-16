defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.FeedUpdater
  alias HTTPoison.Response

  def update(feed) do
    Logger.debug "Requesting feed from #{feed.url}"

    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url),
         {:ok, raw_feed, _} <- FeederEx.parse(body) do
      FeedUpdater.update(feed, raw_feed)
    else
      _ -> {:error, feed}
    end
  end
end
