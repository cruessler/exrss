defmodule ExRss.FeedImporterTest do
  use ExRss.ModelCase

  alias ExRss.FeedImporter

  @opml """
  <?xml version="1.0" encoding="utf-8"?>
  <opml version="1.0">
    <head>
      <dateCreated>Wed, 23 Nov 2016 19:29:49 +0000</dateCreated>
      <title>Tiny Tiny RSS Feed Export</title>
    </head>
    <body>
      <outline text=".elm">
        <outline
          type="rss"
          text="Planet Elm"
          xmlUrl="http://planet.elm-lang.org/feeds.xml"
          htmlUrl="http://planet.elm-lang.org/feeds.xml"/>
      </outline>
      <outline text=".ex">
        <outline
          type="rss"
          text="Phoenix"
          xmlUrl="http://www.phoenixframework.org/blog.rss"
          htmlUrl="http://www.phoenixframework.org/"/>
        <outline
          type="rss"
          text="Elixir Lang"
          xmlUrl="http://feeds.feedburner.com/ElixirLang"
          htmlUrl="http://elixir-lang.org"/>
      </outline>
    <body>
  </html>
  """

  test "imports feed" do
    feeds = FeedImporter.extract_feeds(@opml)

    assert [
      %{title: "Planet Elm", url: _},
      %{title: "Phoenix", url: _},
      %{title: "Elixir Lang", url: _}] = feeds
  end
end
