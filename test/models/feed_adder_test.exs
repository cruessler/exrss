defmodule ExRss.FeedAdderTest do
  use ExRss.ModelCase

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
        type="application/rss+xml"
        title="Atom"
        href="/feed/atom.xml" />
    </head>
    <body></body>
  </html>
  """

  test "extracts feeds" do
    feeds = FeedAdder.extract_feeds(@html)

    assert [
      %{title: "RSS", href: "/feed/rss.xml"},
      %{title: "Atom", href: "/feed/atom.xml"}] = feeds
  end

  test "fails when URI not absolute" do
    assert {:error, :uri_not_absolute} =
      FeedAdder.discover_feeds("example.com")
  end
end
