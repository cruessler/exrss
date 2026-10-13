defmodule ExRss.FeedExporterTest do
  use ExRss.DataCase

  import ExRss.AccountsFixtures
  import ExRss.FeedFixtures

  alias ExRss.FeedExporter

  test "exports feed" do
    %{id: user_id} = user_fixture()
    feed = feed_fixture(%{user_id: user_id})

    assert %{} = feed
    assert length(feed.entries) == 6

    opml = FeedExporter.export_feeds([feed])

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
end
