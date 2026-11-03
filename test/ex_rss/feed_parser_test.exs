defmodule ExRss.FeedParserTest do
  use ExUnit.Case, async: true

  alias ExRss.{FeedFixtures, FeedParser}

  test "counts items" do
    feed = FeedFixtures.rss_fixture("1.atom")

    {:ok, state, _remaining_input} = FeedParser.parse(feed)

    assert %{item_count: 4, element_stack: []} = state
  end

  test "doesn't count items when nesting is incorrect" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <div>
          <entry />
        </div>
      </feed>
      """)

    assert %{item_count: 0, element_stack: []} = state

    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <div>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry />
        </feed>
      </div>
      """)

    assert %{item_count: 0, element_stack: []} = state
  end

  test "doesn't count items when feed is empty" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom" />
      """)

    assert %{item_count: 0, element_stack: []} = state
  end
end
