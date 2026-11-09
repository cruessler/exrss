defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.{Feed, FeedUpdater, Repo}
  alias HTTPoison.{Error, Response}

  def update(feed, fetch \\ &fetch_url/1) do
    with {:ok, %Response{body: body}} <- fetch.(feed.url),
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

  defp fetch_url(url) do
    HTTPoison.get(url, [], follow_redirect: true)
  end
end
