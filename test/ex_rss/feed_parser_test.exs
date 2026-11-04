defmodule ExRss.FeedParserTest do
  use ExUnit.Case, async: true

  alias ExRss.{FeedFixtures, FeedParser}

  test "counts items" do
    feed = FeedFixtures.rss_fixture("1.atom")

    {:ok, state, _remaining_input} = FeedParser.parse(feed)

    assert %{
             element_stack: [],
             feed: %{
               title: "title",
               entries: [
                 %{title: "title"},
                 %{title: "title"},
                 %{title: "title"},
                 %{title: "title"}
               ]
             }
           } = state
  end

  test "parses titles at different levels" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>feed title</title>
        <entry>
          <title>entry title 1</title>
        </entry>
        <entry>
          <title>entry title 2</title>
        </entry>
        <entry>
          <title>entry title 3</title>
        </entry>
      </feed>
      """)

    assert %{
             element_stack: [],
             feed: %{
               title: "feed title",
               entries: [
                 %{title: "entry title 1"},
                 %{title: "entry title 2"},
                 %{title: "entry title 3"}
               ]
             }
           } =
             state
  end

  test "only parses feed title if it's a direct child" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <div>
          <title>ignored</title>
        </div>
      </feed>
      """)

    assert %{
             element_stack: [],
             feed: %{
               title: nil,
               entries: []
             }
           } =
             state
  end

  test "parses a feed's atom:title" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
        <atom:title>title</atom:title>
      </atom:feed>
      """)

    assert %{element_stack: [], feed: %{title: "title", entries: []}} =
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

    assert %{
             element_stack: [],
             feed: %{title: "\n    multiline\n      cdata in title\n  ", entries: []}
           } =
             state
  end

  test "preserves order when title has more than one part" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
         <title>A<![CDATA[B]]>C</title>
      </feed>
      """)

    assert %{element_stack: [], feed: %{title: "ABC", entries: []}} =
             state
  end

  test "preserves whitespace in feed title" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title><![CDATA[A]]> <![CDATA[B]]></title>
      </feed>
      """)

    assert %{element_stack: [], feed: %{title: "A B", entries: []}} =
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

    assert %{element_stack: [], feed: %{title: nil, entries: [%{title: "title"}]}} =
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

    assert %{feed: %{title: nil, entries: []}, element_stack: []} = state

    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <div>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry />
        </feed>
      </div>
      """)

    assert %{feed: nil, element_stack: []} = state
  end

  test "doesn't count items when feed is empty" do
    {:ok, state, _remaining_input} =
      FeedParser.parse("""
      <feed xmlns="http://www.w3.org/2005/Atom" />
      """)

    assert %{feed: %{title: nil, entries: []}, element_stack: []} = state
  end
end
