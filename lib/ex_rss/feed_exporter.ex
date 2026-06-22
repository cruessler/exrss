defmodule ExRss.FeedExporter do
  @prolog [version: "1.0", encoding: "utf-8"]

  def export_feeds(feeds) do
    import Saxy.XML

    # TODO:
    # Check OPML spec/doc to make sure we return a valid document.
    # https://en.wikipedia.org/wiki/OPML
    # https://opml.org/spec2.opml

    feeds =
      feeds
      |> Enum.map(fn feed ->
        element("outline", [type: "rss", text: feed.title, xmlUrl: feed.url], [])
      end)

    head = element("head", [], [])
    body = element("body", [], feeds)
    opml = element("opml", [version: "1.0"], [head, body])

    Saxy.encode!(opml, @prolog)
  end
end
