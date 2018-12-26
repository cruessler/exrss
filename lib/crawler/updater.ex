defmodule ExRss.Crawler.Updater do
  require Logger

  alias ExRss.FeedUpdater
  alias ExRss.Repo
  alias HTTPoison.Response

  def update(feed) do
    with {:ok, %Response{body: body}} <- HTTPoison.get(feed.url, [], follow_redirect: true),
         {:ok, raw_feed} <- parse_feed(body),
         {:ok, %{feed: new_feed}} <- FeedUpdater.update(feed, raw_feed) |> Repo.transaction() do
      {:ok, new_feed}
    else
      _ -> {:error, feed}
    end
  end

  def parse_feed(xml) do
    try do
      FeederEx.parse(xml)
    catch
      :throw, value ->
        {:error, value}
    else
      {:ok, raw_feed, _} ->
        {:ok, raw_feed}

      {:fatal_error, _, error, _, _} ->
        {:error, error}
    end
  end
end
