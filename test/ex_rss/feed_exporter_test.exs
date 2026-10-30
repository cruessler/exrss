defmodule ExRss.FeedExporterTest do
  use ExRss.DataCase

  import ExRss.AccountsFixtures
  import ExRss.FeedFixtures

  alias ExRss.{FeedExporter, FeedImporter}

  test "errors when given no feeds" do
    assert {:error, :no_feeds_to_export} == FeedExporter.export_feeds([])
  end

  test "exports feed" do
    %{id: user_id} = user_fixture()
    feed = feed_fixture(%{user_id: user_id})

    assert %{} = feed
    assert length(feed.entries) == 6

    assert {:ok, opml} = FeedExporter.export_feeds([feed])

    assert opml ==
             String.trim("""
             <?xml version="1.0" encoding="utf-8"?>\
             <opml version="1.0">\
             <head/>\
             <body>\
             <outline type="rss" text="some content" xmlUrl="https://example.com/some-content"/>\
             </body>\
             </opml>
             """)
  end

  test "exports multiple feeds" do
    %{id: user_id} = user_fixture()

    feeds = [
      feed_fixture(%{
        user_id: user_id,
        url: "https://example.com/blog/first.rss",
        title: "First feed"
      }),
      feed_fixture(%{
        user_id: user_id,
        url: "https://example.com/blog/second.rss",
        title: "Second feed"
      }),
      feed_fixture(%{
        user_id: user_id,
        url: "https://example.com/blog/third.rss",
        title: "Third feed"
      })
    ]

    assert {:ok, opml} = FeedExporter.export_feeds(feeds)

    assert opml ==
             String.trim("""
             <?xml version="1.0" encoding="utf-8"?>\
             <opml version="1.0">\
             <head/>\
             <body>\
             <outline type="rss" text="First feed" xmlUrl="https://example.com/blog/first.rss"/>\
             <outline type="rss" text="Second feed" xmlUrl="https://example.com/blog/second.rss"/>\
             <outline type="rss" text="Third feed" xmlUrl="https://example.com/blog/third.rss"/>\
             </body>\
             </opml>
             """)
  end

  test "exports feed with characters that need escaping" do
    %{id: user_id} = user_fixture()

    feed =
      feed_fixture(%{
        user_id: user_id,
        url: "https://example.com/blog?page=1&category=news",
        title: ~s(Assortment of XML special characters "'&<>)
      })

    assert %{} = feed

    assert {:ok, opml} = FeedExporter.export_feeds([feed])

    assert opml ==
             String.trim("""
             <?xml version="1.0" encoding="utf-8"?>\
             <opml version="1.0">\
             <head/>\
             <body>\
             <outline type="rss" text="Assortment of XML special characters &quot;&apos;&amp;&lt;&gt;" xmlUrl="https://example.com/blog?page=1&amp;category=news"/>\
             </body>\
             </opml>
             """)

    [feed] = FeedImporter.extract_feeds(opml)

    assert %{
             url: "https://example.com/blog?page=1&category=news",
             title: ~s(Assortment of XML special characters "'&<>)
           } = feed
  end
end
