defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.FeedUpdater
  alias ExRss.Repo
  alias HTTPoison.Response

  def update(feed) do
    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url),
         {:ok, raw_feed, _} <- FeederEx.parse(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction
      do
      {:ok, new_feed}
    else
      _ -> {:error, feed}
    end
  end
end
