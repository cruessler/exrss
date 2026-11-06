defmodule ExRss.FeedParserTest do
  use ExUnit.Case, async: true

  alias ExRss.{Feed, FeedFixtures, FeedParser}

  describe "Atom feeds" do
    test "1.atom" do
      feed = FeedFixtures.rss_fixture("1.atom")

      {:ok, feed} = FeedParser.parse(feed)

      assert %{
               title: "title",
               entries: [
                 %{title: "title", link: "https://example.com/blog/1"},
                 %{title: "title", link: "https://example.com/blog/2"},
                 %{title: "title", link: "https://example.com/blog/3"},
                 %{title: "title", link: "https://example.com/blog/4"}
               ]
             } =
               feed
    end

    test "parses entry links" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>entry title 1</title>
            <link href="https://example.com/1" />
          </entry>
          <entry>
            <title>entry title 2</title>
            <link href="https://example.com/2" rel="alternate" />
          </entry>
          <entry>
            <title>entry title 3</title>
            <link href="https://example.com/3" rel="invalid" />
          </entry>
          <entry>
            <title>entry title 4</title>
            <link href="https://example.com/self" rel="self" />
            <link href="https://example.com/alternate" rel="alternate" />
          </entry>
          <entry>
            <title>entry title 5</title>
            <link href="https://example.com/shorturl" rel="shorturl" />
            <link href="https://example.com/alternate" rel="alternate" />
          </entry>
          <entry>
            <title>entry title 6</title>
            <link />
            <link href="" />
            <link href="https://example.com/alternate" rel="alternate" />
          </entry>
        </feed>
        """)

      assert %{
               title: "feed title",
               entries: [
                 %{title: "entry title 1", link: "https://example.com/1"},
                 %{title: "entry title 2", link: "https://example.com/2"},
                 %{title: "entry title 3", link: "https://example.com/3"},
                 %{title: "entry title 4", link: "https://example.com/self"},
                 %{title: "entry title 5", link: "https://example.com/alternate"},
                 %{title: "entry title 6", link: "https://example.com/alternate"}
               ]
             } =
               feed
    end

    test "ignores <title> inside <link>" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>correct title</title>
            <link href="https://example.com/1">
              <title>should be ignored</title>
            </link>
          </entry>
        </feed>
        """)

      assert %{
               title: "feed title",
               entries: [
                 %{title: "correct title", link: "https://example.com/1"}
               ]
             } =
               feed
    end

    test "parses titles at different levels" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>entry title 1</title>
          </entry>
          <entry>
            <title>entry title 2</title>
          </entry>
          <entry>
            <title>entry title 3</title>
          </entry>
        </feed>
        """)

      assert %{
               title: "feed title",
               entries: [
                 %{title: "entry title 1"},
                 %{title: "entry title 2"},
                 %{title: "entry title 3"}
               ]
             } =
               feed
    end

    test "only parses feed title if it's a direct child" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <div>
            <title>ignored</title>
          </div>
        </feed>
        """)

      assert %{
               title: nil,
               entries: []
             } =
               feed
    end

    test "only parses toplevel text in title" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>A<div><title>ignored</title></div>C</title>
        </feed>
        """)

      assert %{
               title: "AC",
               entries: []
             } =
               feed
    end

    test "parses a feed's atom:title" do
      {:ok, feed} =
        FeedParser.parse("""
        <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
          <atom:title>title</atom:title>
        </atom:feed>
        """)

      assert %{title: "title", entries: []} = feed
    end

    test "parses a feed's title containing multiline CDATA" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>
            <![CDATA[multiline
              cdata in title]]>
          </title>
        </feed>
        """)

      assert %{title: "\n    multiline\n      cdata in title\n  ", entries: []} = feed
    end

    test "preserves order when title has more than one part" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
           <title>A<![CDATA[B]]>C</title>
        </feed>
        """)

      assert %{title: "ABC", entries: []} = feed
    end

    test "preserves whitespace in feed title" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title><![CDATA[A]]> <![CDATA[B]]></title>
        </feed>
        """)

      assert %{title: "A B", entries: []} = feed
    end

    test "does not parse a nested entry's title as a feed title" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>title</title>
          </entry>
        </feed>
        """)

      assert %{title: nil, entries: [%{title: "title"}]} = feed
    end

    test "returns no items when nesting is incorrect" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <div>
            <entry />
          </div>
        </feed>
        """)

      assert %{title: nil, entries: []} = feed

      result =
        FeedParser.parse("""
        <div>
          <feed xmlns="http://www.w3.org/2005/Atom">
            <entry />
          </feed>
        </div>
        """)

      assert {:error, :no_feed_found} = result
    end

    test "returns no items when feed is empty" do
      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom" />
        """)

      assert %{title: nil, entries: []} = feed
    end

    test "Atom date fields" do
      {:ok, feed} =
        Feed.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>entry title 1</title>
            <published>2022-08-12T21:07:00+02:00</published>
            <updated>2026-08-12T21:07:00+02:00</updated>
          </entry>
          <entry>
            <title>entry title 2</title>
            <updated>2026-08-12T21:07:00+02:00</updated>
          </entry>
          <entry>
            <title>entry title 3</title>
            <published>2022-08-12T21:07:00+02:00</published>
          </entry>
          <entry>
            <title>entry title 4</title>
            <updated>2026-08-12T21:07:00+02:00</updated>
            <published>2022-08-12T21:07:00+02:00</published>
          </entry>
        </feed>
        """)

      assert %{
               entries: [
                 %{updated: "2026-08-12T21:07:00+02:00"},
                 %{updated: "2026-08-12T21:07:00+02:00"},
                 %{updated: nil},
                 %{updated: "2026-08-12T21:07:00+02:00"}
               ]
             } = feed

      {:ok, feed} =
        FeedParser.parse("""
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>entry title 1</title>
            <published>2022-08-12T21:07:00+02:00</published>
            <updated>2026-08-12T21:07:00+02:00</updated>
          </entry>
          <entry>
            <title>entry title 2</title>
            <updated>2026-08-12T21:07:00+02:00</updated>
          </entry>
          <entry>
            <title>entry title 3</title>
            <published>2022-08-12T21:07:00+02:00</published>
          </entry>
          <entry>
            <title>entry title 4</title>
            <updated>2026-08-12T21:07:00+02:00</updated>
            <published>2022-08-12T21:07:00+02:00</published>
          </entry>
        </feed>
        """)

      assert %{
               entries: [
                 %{title: "entry title 1", updated: "2026-08-12T21:07:00+02:00"},
                 %{title: "entry title 2", updated: "2026-08-12T21:07:00+02:00"},
                 %{title: "entry title 3", updated: nil},
                 %{title: "entry title 4", updated: "2026-08-12T21:07:00+02:00"}
               ]
             } = feed
    end

    test "returns error for truncated input" do
      result =
        FeedParser.parse("""
              <feed xmlns="http://www.w3.org/2005/Atom">
                <title>feed title</title>
                <entry>
                  <title>entry title 1</title>
        """)

      assert {:error, {:xml_parsing_failed, _reason}} = result
    end
  end

  describe "RSS 2.0 feeds" do
    test "extracts the feed's title" do
      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
            <title>title</title>
          </channel>
        </rss>
        """)

      assert %{title: "title", entries: []} = feed
    end

    test "handles empty title" do
      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
            <title></title>
          </channel>
        </rss>
        """)

      assert %{title: nil, entries: []} = feed

      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
            <title />
          </channel>
        </rss>
        """)

      assert %{title: nil, entries: []} = feed

      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
          </channel>
        </rss>
        """)

      assert %{title: nil, entries: []} = feed

      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
            <title> </title>
          </channel>
        </rss>
        """)

      assert %{title: " ", entries: []} = feed
    end

    test "does not detect a feed that has version '1.0'" do
      result =
        FeedParser.parse("""
        <rss version="1.0">
          <channel>
            <title>title</title>
          </channel>
        </rss>
        """)

      assert {
               :error,
               :no_feed_found
             } =
               result
    end

    test "only accepts <channel> as direct child of <rss>" do
      result =
        FeedParser.parse("""
        <rss version="2.0">
          <div>
            <channel>
              <title>title</title>
            </channel>
          </div>
        </rss>
        """)

      assert {
               :error,
               :no_feed_found
             } =
               result
    end

    test "parses items" do
      {:ok, feed} =
        FeedParser.parse("""
        <rss version="2.0">
          <channel>
            <title>title</title>
            <item>
              <title>item title 1</title>
              <link>https://example.com/1</link>
              <pubDate>2022-11-11</pubDate>
            </item>
            <item>
              <title>item title 2</title>
              <link>https://example.com/2</link>
              <pubDate>2022-11-12</pubDate>
            </item>
            <item>
              <title>item title 3</title>
              <link>https://example.com/3</link>
              <pubDate>2022-11-13</pubDate>
            </item>
          </channel>
        </rss>
        """)

      assert %{
               title: "title",
               entries: [
                 %{title: "item title 1", link: "https://example.com/1", updated: "2022-11-11"},
                 %{title: "item title 2", link: "https://example.com/2", updated: "2022-11-12"},
                 %{title: "item title 3", link: "https://example.com/3", updated: "2022-11-13"}
               ]
             } =
               feed
    end
  end

  describe "FeederEx and FeedParser yield the same result" do
    defp test_fixture(filename) do
      feed = %{id: 1, url: "https://example.com/blog/feed.xml"}
      xml = FeedFixtures.rss_fixture(filename)

      {:ok, feeder_ex_feed} = xml |> Feed.parse()

      # We drop timestamps that are not hardcoded. Both `:inserted_at` and
      # `:updated_at` are taken from `DateTime.utc_now()` in `Entry.parse()`.
      feeder_ex_entries =
        Feed.parse_entries(feed, feeder_ex_feed)
        |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

      {:ok, feed_parser_feed} = xml |> FeedParser.parse()

      feed_parser_entries =
        Feed.parse_entries(feed, feed_parser_feed)
        |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

      assert length(feeder_ex_entries) > 0
      assert feeder_ex_entries == feed_parser_entries
      assert feeder_ex_feed.title == feed_parser_feed.title
    end

    test "1.atom" do
      test_fixture("1.atom")
    end

    test "1.using-namespaces.atom" do
      test_fixture("1.using-namespaces.atom")
    end

    test "1.no-links.atom" do
      test_fixture("1.no-links.atom")
    end

    test "1.rss" do
      test_fixture("1.rss")
    end

    test "1.empty-links.rss" do
      test_fixture("1.empty-links.rss")
    end

    test "1.empty-feed.rss" do
      xml = FeedFixtures.rss_fixture("1.empty-feed.rss")

      {:ok, feeder_ex_feed} = xml |> Feed.parse()
      {:ok, feed_parser_feed} = xml |> FeedParser.parse()

      assert length(feeder_ex_feed.entries) == 0
      assert length(feed_parser_feed.entries) == 0
      assert feeder_ex_feed.title == feed_parser_feed.title
    end

    test "1.truncated.rss" do
      xml = FeedFixtures.rss_fixture("1.truncated.rss")

      {:error, _} = xml |> Feed.parse()
      {:error, {:xml_parsing_failed, _reason}} = xml |> FeedParser.parse()
    end

    test "unescaped & in attribute yields error" do
      xml = """
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>feed title</title>
          <entry>
            <title>entry title 1</title>
            <link href="https://example.com/1" title="A & B" />
          </entry>
        </feed>
      """

      assert {:error, _} = xml |> Feed.parse()
      assert {:error, {:xml_parsing_failed, _reason}} = xml |> FeedParser.parse()
    end
  end
end
