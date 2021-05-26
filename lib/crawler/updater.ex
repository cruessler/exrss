defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.Feed
  alias ExRss.FeedUpdater
  alias ExRss.Repo
  alias HTTPoison.{Error, Response}

  def update(feed) do
    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url, [], follow_redirect: true),
         {:ok, raw_feed} <- Feed.parse(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction() do
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
end
