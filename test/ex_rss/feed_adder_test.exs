defmodule ExRss.FeedAdderTest do
  use ExRss.DataCase

  alias ExRss.FeedAdder

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

  test "extracts feeds" do
    {:ok, html} = Floki.parse_document(@html)

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

    assert is_nil(FeedAdder.extract_frequency_info(raw_feed))
  end
end
