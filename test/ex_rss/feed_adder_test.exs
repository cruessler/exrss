defmodule ExRss.FeedAdderTest do
  use ExRss.DataCase

  import ExUnit.CaptureLog, only: [with_log: 1]

  alias ExRss.{FeedAdder, FeedFixtures}

  @html """
  <!DOCTYPE html>
  <html>
    <head>
      <link
        rel="alternate"
        type="application/rss+xml"
        title="RSS"
        href="/feed/rss.xml" />
      <link
        rel="alternate"
        type="application/atom+xml"
        title="Atom"
        href="/feed/atom.xml" />
    </head>
    <body></body>
  </html>
  """

  @rss """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title>example.com/blog</title>
      <description></description>
      <link></link>
      <atom:link href="" rel="self" type="application/rss+xml"/>
      <pubDate>Sun, 15 Oct 2017 23:16:15 +0200</pubDate>
      <lastBuildDate>Sun, 15 Oct 2017 23:16:15 +0200</lastBuildDate>
      <generator>Jekyll v3.3.0</generator>

      <item>
        <title>First post title</title>
        <description></description>
        <pubDate>Sun, 15 Oct 2017 23:11:00 +0200</pubDate>
        <link></link>
        <guid isPermaLink="true"></guid>
      </item>

      <item>
        <title>Second post title</title>
        <description></description>
        <pubDate>Sun, 15 Oct 2017 12:47:00 +0200</pubDate>
        <link></link>
        <guid isPermaLink="true"></guid>
      </item>

      <item>
        <title>Third post title</title>
        <description></description>
        <pubDate>Sat, 05 Nov 2016 18:07:00 +0100</pubDate>
        <link></link>
        <guid isPermaLink="true"></guid>
      </item>
    </channel>
  </rss>
  """

  @rss_whithout_pubdate """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title>example.com/blog</title>
      <description></description>
      <link></link>
      <atom:link href="" rel="self" type="application/rss+xml"/>
      <pubDate>Sun, 15 Oct 2017 23:16:15 +0200</pubDate>
      <lastBuildDate>Sun, 15 Oct 2017 23:16:15 +0200</lastBuildDate>
      <generator>Jekyll v3.3.0</generator>

      <item>
        <title>First post title</title>
        <description></description>
        <link></link>
        <guid isPermaLink="true"></guid>
      </item>
    </channel>
  </rss>
  """

  test "discover feeds" do
    url = "https://example.com/feed"
    uri = URI.parse(url)
    rss_url = "https://example.com/feed/rss.xml"
    rss_uri = URI.parse(rss_url)
    atom_url = "https://example.com/feed/atom.xml"
    atom_uri = URI.parse(atom_url)

    fetch = fn
      ^url -> {:ok, @html, uri}
      ^rss_url -> {:ok, @rss, rss_uri}
      ^atom_url -> {:ok, @rss, atom_uri}
    end

    feeds = FeedAdder.discover_feeds(url, fetch)

    assert {:ok,
            [
              %{title: "RSS", href: "/feed/rss.xml", frequency: %{seconds: 29_736_240, posts: 3}},
              %{
                title: "Atom",
                href: "/feed/atom.xml",
                frequency: %{seconds: 29_736_240, posts: 3}
              }
            ]} = feeds
  end

  describe "FeedAdder.discover_feed/2" do
    defp discover_fixture(filename) do
      url = "https://example.com/feed"
      uri = URI.parse(url)
      xml = FeedFixtures.rss_fixture(filename)

      fetch = fn
        ^url -> {:ok, xml, uri}
      end

      FeedAdder.discover_feed(url, fetch)
    end

    test "1.atom" do
      {:ok, feed} = discover_fixture("1.atom")

      assert %{
               frequency: %{posts: 4, seconds: 17_202_180},
               href: nil,
               title: "title",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.no-links.atom" do
      {:ok, feed} = discover_fixture("1.no-links.atom")

      assert %{
               frequency: %{posts: 4, seconds: 17_202_180},
               href: nil,
               title: "title",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.rss" do
      {:ok, feed} = discover_fixture("1.rss")

      assert %{
               url: "https://example.com/blog/feed/",
               frequency: %{seconds: 0, posts: 4},
               href: "https://example.com/blog/feed/",
               title: "title"
             } = feed
    end

    test "1.empty-links.rss" do
      {:ok, feed} = discover_fixture("1.empty-links.rss")

      assert %{
               url: "https://example.com/blog/feed/",
               frequency: %{seconds: 0, posts: 3},
               href: "https://example.com/blog/feed/",
               title: "title"
             } = feed
    end

    test "1.empty-feed.rss" do
      {:ok, feed} = discover_fixture("1.empty-feed.rss")

      assert %{
               url: "https://example.com/blog/feed/",
               frequency: %{seconds: :not_available, posts: 0},
               href: "https://example.com/blog/feed/",
               title: "title"
             } = feed
    end

    test "1.truncated.rss" do
      assert {:error, _error} = discover_fixture("1.truncated.rss")
    end

    test "propagates HTTPoison error" do
      url = "https://example.com/feed"

      fetch = fn
        ^url -> {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}}
      end

      assert {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}} =
               FeedAdder.discover_feed(url, fetch)
    end
  end

  describe "FeedAdder.add_discovery_info/2" do
    defp add_discovery_info_fixture(filename) do
      url = "https://example.com/feed"
      uri = URI.parse(url)
      xml = FeedFixtures.rss_fixture(filename)

      fetch = fn
        ^url -> {:ok, xml, uri}
      end

      feed = %{title: "Discovered title", href: "/feed", url: url}

      FeedAdder.add_discovery_info(feed, fetch)
    end

    test "1.atom" do
      feed = add_discovery_info_fixture("1.atom")

      assert %{
               frequency: %{seconds: 17_202_180, posts: 4},
               newest_entries: [
                 %{
                   link: "https://example.com/blog/1",
                   title: "title",
                   updated: "2026-08-12T21:07:00+02:00"
                 },
                 %{
                   link: "https://example.com/blog/2",
                   title: "title",
                   updated: "2026-05-09T18:52:00+02:00"
                 },
                 %{
                   link: "https://example.com/blog/3",
                   title: "title",
                   updated: "2026-03-14T10:45:00+01:00"
                 }
               ],
               title: "Discovered title",
               href: "/feed",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.no-links.atom" do
      feed = add_discovery_info_fixture("1.no-links.atom")

      assert %{
               frequency: %{seconds: 17_202_180, posts: 4},
               newest_entries: [
                 %{
                   link: "https://example.com/blog/1",
                   title: "title",
                   updated: "2026-08-12T21:07:00+02:00"
                 },
                 %{
                   link: "https://example.com/blog/2",
                   title: "title",
                   updated: "2026-05-09T18:52:00+02:00"
                 },
                 %{
                   link: nil,
                   title: "title",
                   updated: "2026-03-14T10:45:00+01:00"
                 }
               ],
               title: "Discovered title",
               href: "/feed",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.rss" do
      feed = add_discovery_info_fixture("1.rss")

      assert %{
               frequency: %{seconds: 0, posts: 4},
               newest_entries: [
                 %{
                   link: "https://example.com/blog/1",
                   title: "title",
                   updated: "Wed, 28 Oct 2026 10:54:05 +0000"
                 },
                 %{
                   link: "https://example.com/blog/2",
                   title: "title",
                   updated: "Wed, 28 Oct 2026 10:54:05 +0000"
                 },
                 %{
                   link: "https://example.com/blog/3",
                   title: "title with space trimmed",
                   updated: "Wed, 28 Oct 2026 10:54:05 +0000"
                 }
               ],
               title: "Discovered title",
               href: "/feed",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.empty-feed.rss" do
      feed = add_discovery_info_fixture("1.empty-feed.rss")

      assert %{
               frequency: %{seconds: :not_available, posts: 0},
               newest_entries: [],
               title: "Discovered title",
               href: "/feed",
               url: "https://example.com/feed"
             } = feed
    end

    test "1.truncated.rss" do
      {info, log} =
        with_log(fn -> add_discovery_info_fixture("1.truncated.rss") end)

      assert %{
               url: "https://example.com/feed",
               title: "Discovered title",
               href: "/feed",
               frequency: nil
             } =
               info

      assert log =~ "Could not add frequency info"
    end

    test "returns no frequency info when fetch returns error" do
      url = "https://example.com/feed"

      fetch = fn
        ^url -> {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}}
      end

      feed = %{title: "Discovered title", href: "/feed", url: url}

      {info, log} =
        with_log(fn -> FeedAdder.add_discovery_info(feed, fetch) end)

      assert %{
               url: "https://example.com/feed",
               title: "Discovered title",
               href: "/feed",
               frequency: nil
             } =
               info

      assert log =~ "Could not add frequency info"
    end
  end

  test "extracts feeds" do
    html = LazyHTML.from_document(@html)

    feeds = FeedAdder.extract_feeds(html)

    assert [%{title: "RSS", href: "/feed/rss.xml"}, %{title: "Atom", href: "/feed/atom.xml"}] =
             feeds
  end

  test "extracts feed metadata" do
    {:ok, raw_feed, _} = FeederEx.parse(@rss)

    candidate = FeedAdder.extract_candidate(raw_feed)

    assert %{url: _, title: _, href: _, frequency: _} = candidate
  end

  test "fails when URI not absolute" do
    assert {:error, :uri_not_absolute} = FeedAdder.discover_feeds("example.com")
  end

  test "extracts frequency info" do
    {:ok, raw_feed, _} = FeederEx.parse(@rss)

    frequency_info = FeedAdder.extract_frequency_info(raw_feed)

    assert %{posts: 3, seconds: 29_736_240} = frequency_info
  end

  test "doesn’t extract frequency info when no publication dates are given" do
    {:ok, raw_feed, _} = FeederEx.parse(@rss_whithout_pubdate)

    frequency_info = FeedAdder.extract_frequency_info(raw_feed)

    assert %{posts: 1, seconds: :not_available} = frequency_info
  end
end
