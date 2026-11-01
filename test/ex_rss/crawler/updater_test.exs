defmodule ExRss.Crawler.UpdaterTest do
  use ExRss.DataCase, async: true

  alias ExRss.Crawler.Updater
  alias ExRss.{AccountsFixtures, Entry, Feed, FeedFixtures, Repo}

  describe "Updater.update/2" do
    test "adds new entries to feed" do
      url = "https://example.com/feed"
      xml = FeedFixtures.rss_fixture("1.rss")

      fetch = fn
        ^url -> {:ok, %HTTPoison.Response{body: xml}}
      end

      user = AccountsFixtures.user_fixture()

      feed =
        Feed.changeset(%Feed{user_id: user.id, url: url})
        |> Repo.insert!()

      {:ok, updated_feed} = Updater.update(feed, fetch)

      assert updated_feed.id == feed.id

      feed = Repo.get!(Feed, feed.id) |> Repo.preload(entries: from(e in Entry, order_by: :url))

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: [
                 %{title: "title", url: "https://example.com/blog/1"},
                 %{title: "title", url: "https://example.com/blog/2"},
                 %{title: "title", url: "https://example.com/blog/3"}
               ]
             } = feed
    end
  end
end
