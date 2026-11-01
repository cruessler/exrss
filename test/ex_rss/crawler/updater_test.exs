defmodule ExRss.Crawler.UpdaterTest do
  use ExUnit.Case, async: true

  alias ExRss.Crawler.Updater
  alias ExRss.{AccountsFixtures, Feed, FeedFixtures, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    :ok
  end

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

      Updater.update(feed, fetch)

      feed = Repo.get!(Feed, feed.id) |> Repo.preload(:entries)

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
