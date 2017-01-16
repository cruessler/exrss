defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.FeedUpdater
  alias ExRss.Repo
  alias HTTPoison.Response

  def update(feed) do
    Logger.debug "Requesting feed from #{feed.url}"

    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url),
         {:ok, raw_feed, _} <- FeederEx.parse(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction
      do
      Logger.debug "Updated feed #{feed.title}"

      {:ok, new_feed}
    else
      _ -> {:error, feed}
    end
  end
end
