defmodule ExRss.FeedParserTest do
  use ExUnit.Case, async: true

  alias ExRss.{FeedFixtures, FeedParser}

  test "counts items" do
    feed = FeedFixtures.rss_fixture("1.atom")

    {:ok, state, _remaining_input} = FeedParser.parse(feed)

    assert %{item_count: 4} = state
  end
end
