defmodule ExRss.Crawler.UpdaterTest do
  use ExRss.DataCase, async: true

  import ExUnit.CaptureLog, only: [with_log: 1]

  alias ExRss.Crawler.Updater
  alias ExRss.{AccountsFixtures, Entry, Feed, FeedFixtures, FeedParser, Repo}

  describe "Updater.update/2" do
    defp update_feed(filename) do
      url = "https://example.com/feed"
      xml = FeedFixtures.rss_fixture(filename)

      fetch = fn
        ^url -> {:ok, %HTTPoison.Response{body: xml}}
      end

      user = AccountsFixtures.user_fixture()

      feed =
        Feed.changeset(%Feed{user_id: user.id, url: url})
        |> Repo.insert!()

      {:ok, updated_feed} = Updater.update(feed, fetch)

      assert updated_feed.id == feed.id

      Repo.get!(Feed, feed.id) |> Repo.preload(entries: from(e in Entry, order_by: :url))
    end

    test "1.atom" do
      feed = update_feed("1.atom")

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: [
                 %{title: "title", url: "https://example.com/blog/1"},
                 %{title: "title", url: "https://example.com/blog/2"},
                 %{title: "title", url: "https://example.com/blog/3"},
                 %{title: "title", url: "https://example.com/blog/4"}
               ]
             } = feed
    end

    test "1.no-links.atom" do
      feed = update_feed("1.no-links.atom")

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: [
                 %{title: "title", url: "https://example.com/blog/1"},
                 %{title: "title", url: "https://example.com/blog/2"},
                 %{title: "title", url: "https://example.com/blog/4"}
               ]
             } = feed
    end

    test "1.rss" do
      feed = update_feed("1.rss")

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: [
                 %{title: "title", url: "https://example.com/blog/1"},
                 %{title: "title", url: "https://example.com/blog/2"},
                 %{title: "title with space trimmed", url: "https://example.com/blog/3"},
                 %{title: "title", url: "https://example.com/blog/4"}
               ]
             } = feed
    end

    test "1.empty-links.rss" do
      feed = update_feed("1.empty-links.rss")

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: [
                 %{title: "title", url: "https://example.com/blog/1"},
                 %{title: "title", url: "https://example.com/blog/2"}
               ]
             } = feed
    end

    test "1.empty-feed.rss" do
      feed = update_feed("1.empty-feed.rss")

      assert %{
               title: "title",
               url: "https://example.com/feed",
               entries: []
             } = feed
    end

    test "does not make changes when feed is malformed" do
      url = "https://example.com/feed"
      xml = FeedFixtures.rss_fixture("1.truncated.rss")

      fetch = fn
        ^url -> {:ok, %HTTPoison.Response{body: xml}}
      end

      user = AccountsFixtures.user_fixture()

      feed =
        Feed.changeset(%Feed{user_id: user.id, title: "Original title", url: url})
        |> Repo.insert!()

      {:error, _} = Updater.update(feed, fetch)

      feed = Repo.get!(Feed, feed.id) |> Repo.preload(entries: from(e in Entry, order_by: :url))

      assert %{
               title: "Original title",
               url: "https://example.com/feed",
               entries: []
             } = feed
    end

    test "returns error when fetch fails" do
      url = "https://example.com/feed"

      fetch = fn
        ^url -> {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}}
      end

      user = AccountsFixtures.user_fixture()

      feed =
        Feed.changeset(%Feed{user_id: user.id, title: "Original title", url: url})
        |> Repo.insert!()

      assert {:error, :econnrefused} = Updater.update(feed, fetch)
    end

    defp test_candidate_parser(candidate_parser) do
      url = "https://example.com/feed"
      xml = FeedFixtures.rss_fixture("1.rss")

      fetch = fn
        ^url -> {:ok, %HTTPoison.Response{body: xml}}
      end

      user = AccountsFixtures.user_fixture()

      feed =
        Feed.changeset(%Feed{user_id: user.id, url: url})
        |> Repo.insert!()

      {:ok, updated_feed} =
        Updater.update(feed, fetch,
          compare_with_candidate_parser?: true,
          candidate_parser: candidate_parser
        )

      assert updated_feed.id == feed.id

      feed = Repo.get!(Feed, feed.id) |> Repo.preload(entries: from(e in Entry, order_by: :url))

      assert %{
               title: "title",
               url: "https://example.com/feed"
             } = feed
    end

    test "doesn't fail when candidate_parser fails" do
      test_candidate_parser(fn _ -> raise "parser failed " end)
      test_candidate_parser(fn _ -> throw(:parser_failed) end)
      test_candidate_parser(fn _ -> exit(:process_exited) end)
    end

    test "detects when parsers agree" do
      previous_level = Logger.level()
      Logger.configure(level: :info)

      {_, log} =
        with_log(fn ->
          test_candidate_parser(&FeedParser.parse/1)
        end)

      on_exit(fn -> Logger.configure(level: previous_level) end)

      assert log =~ "FeederEx and FeedParser agree"
    end

    test "does not treat mismatch in updated as parser mismatch" do
      {_, log} =
        with_log(fn ->
          test_candidate_parser(fn xml ->
            {:ok, feed} = FeedParser.parse(xml)

            entries =
              feed.entries
              |> Enum.map(fn entry -> %{entry | updated: "   #{entry.updated}   "} end)

            {:ok, %{feed | entries: entries}}
          end)
        end)

      assert log =~ "FeederEx and FeedParser agree"
    end

    test "detects mismatch in title" do
      {_, log} =
        with_log(fn ->
          test_candidate_parser(fn xml ->
            {:ok, feed} = FeedParser.parse(xml)

            {:ok, %{feed | title: "title does not match"}}
          end)
        end)

      assert log =~ "Mismatch between FeederEx and FeedParser detected"
    end

    test "detects mismatch in entries" do
      {_, log} =
        with_log(fn ->
          test_candidate_parser(fn xml ->
            {:ok, feed} = FeedParser.parse(xml)

            {:ok, %{feed | entries: []}}
          end)
        end)

      assert log =~ "Mismatch between FeederEx and FeedParser detected"
    end
  end
end
