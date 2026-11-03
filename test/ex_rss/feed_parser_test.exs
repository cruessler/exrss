defmodule ExRss.FeedParserTest do
  use ExUnit.Case, async: true

  alias ExRss.{FeedFixtures, FeedParser}

  test "counts items" do
    feed = FeedFixtures.rss_fixture("1.atom")

    {:ok, state, _remaining_input} = FeedParser.parse(feed)

    assert %{item_count: 4, element_stack: [], feed: %{title: "title"}} = state
  end

  test "parses a feed's atom:title" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
        <atom:title>title</atom:title>
      </atom:feed>
      """)

    assert %{item_count: 0, element_stack: [], feed: %{title: "title"}} =
             state
  end

  test "parses a feed's title containing multiline CDATA" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>
          <![CDATA[multiline
            cdata in title]]>
        </title>
      </feed>
      """)

    assert %{item_count: 0, element_stack: [], feed: %{title: "multiline\n      cdata in title"}} =
             state
  end

  test "does not parse a nested entry's title as a feed title" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <title>title</title>
        </entry>
      </feed>
      """)

    assert %{item_count: 1, element_stack: [], feed: %{title: ""}} =
             state
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
