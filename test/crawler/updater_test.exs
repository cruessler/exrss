defmodule ExRss.Crawler.UpdaterTest do
  use ExUnit.Case, async: true

  alias ExRss.Crawler.Updater

  @xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title></title>
      <description></description>
      <link></link>
      <pubDate></pubDate>
      <item>
        <title></title>
        <description></description>
        <pubDate></pubDate>
      </item>
    </channel>
  </rss>
  """

  test "parses feed" do
    assert {:ok, %{entries: [_]}} = Updater.parse_feed(@xml)
    assert {:error, _} = Updater.parse_feed("")
  end
end
