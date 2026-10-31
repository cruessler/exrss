defmodule ExRss.FeedTest do
  use ExRss.DataCase

  alias Ecto.Changeset
  alias ExRss.{Entry, Feed, FeedsFixtures, User}
  alias Timex.Duration

  @valid_attrs %{title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Feed.changeset(%Feed{user_id: 1}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Feed.changeset(%Feed{}, @invalid_attrs)
    refute changeset.valid?
  end

  @now DateTime.truncate(DateTime.utc_now(), :second)
  @timeout Duration.from_minutes(60) |> Duration.to_seconds() |> round
  @max_timeout Duration.from_days(1) |> Duration.to_seconds() |> round

  test "schedule_update_on_error" do
    changeset =
      %Feed{retries: 0, next_update_at: @now}
      |> Changeset.change()
      |> Feed.schedule_update_on_error(@now)

    diff = Timex.diff(changeset.changes.next_update_at, @now, :seconds)

    assert %{retries: 1} = changeset.changes
    assert diff == @timeout
    assert changeset.changes.next_update_at.microsecond == {0, 0}

    changeset =
      changeset
      |> Feed.schedule_update_on_error(@now)

    assert %{retries: 2} = changeset.changes
    assert Timex.compare(changeset.changes.next_update_at, @now) == 1
  end

  test "schedule_update_on_error with retries that cause an ArithmeticError" do
    changeset =
      %Feed{retries: 2000, next_update_at: @now}
      |> Changeset.change()
      |> Feed.schedule_update_on_error(@now)

    diff = Timex.diff(changeset.changes.next_update_at, @now, :seconds)

    assert %{retries: 2001} = changeset.changes
    assert diff == @max_timeout
  end

  test "schedule_update has a maximum timeout" do
    changeset =
      %Feed{retries: 20, next_update_at: @now}
      |> Changeset.change()
      |> Feed.schedule_update_on_error(@now)

    diff = Timex.diff(changeset.changes.next_update_at, @now, :seconds)

    assert diff == @max_timeout
  end

  test "schedule_update schedules update in the future" do
    next_update_at =
      @now
      |> Timex.subtract(Duration.from_days(2))

    changeset =
      %Feed{retries: 20, next_update_at: next_update_at}
      |> Changeset.change()
      |> Feed.schedule_update_on_error(@now)

    diff = Timex.diff(changeset.changes.next_update_at, @now, :seconds)

    assert diff == @max_timeout
  end

  test "schedule_update_on_success" do
    changeset =
      %Feed{retries: 0, next_update_at: @now}
      |> Changeset.change()
      |> Feed.schedule_update_on_success(@now)

    diff = Timex.diff(changeset.changes.next_update_at, @now, :seconds)

    assert Changeset.get_field(changeset, :retries) == 0
    assert diff == @timeout
  end

  setup do
    Repo.insert!(%User{id: 1, email: "jane@doe.com"})
    Repo.insert!(%Feed{id: 1, user_id: 1, title: "Title", url: "http://example.com"})

    Repo.insert!(%Entry{
      id: 1,
      url: "http://example.com/1",
      title: "Title",
      raw_posted_at: "Sun, 21 Dec 2014 16:08:00 +0100",
      read: false,
      feed_id: 1
    })

    Repo.insert!(%Entry{
      id: 2,
      url: "http://example.com/2",
      title: "Title 2",
      raw_posted_at: "Sun, 21 Dec 2015 16:08:00 +0100",
      read: false,
      feed_id: 1
    })

    :ok
  end

  test "mark_as_read" do
    changeset =
      Repo.get!(Feed, 1)
      |> Repo.preload(:entries)
      |> Feed.mark_as_read()

    for e <- Changeset.get_field(changeset, :entries), do: assert(e.read == true)
  end

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
    assert {:ok, %{entries: [_]}} = Feed.parse(@xml)
    assert {:error, _} = Feed.parse("")
  end

  describe "Feed.parse_entries" do
    test "skips entries without actual links and resolves links correctly" do
      entries =
        for link <- [nil, "", "/blog/1", "https://example.com/blog/feed.xml"] do
          %{title: "title", link: link, updated: "2021-11-06"}
        end

      feed = %{id: 1, url: "https://example.com/blog/feed.xml"}

      entries =
        Feed.parse_entries(feed, %{
          title: "title",
          entries: entries
        })
        |> Enum.map(&{&1.url, &1.feed_id})

      assert [{"https://example.com/blog/1", 1}, {"https://example.com/blog/feed.xml", 1}] =
               entries
    end

    test "returns empty list when feed has no entries" do
      feed = %{id: 1, url: "https://example.com/blog/feed.xml"}

      entries =
        Feed.parse_entries(feed, %{
          title: "title",
          entries: []
        })

      assert [] = entries
    end
  end

  describe "FeederEx and SweetXml yield the same result" do
    defp test_fixture(filename) do
      feed = %{id: 1, url: "https://example.com/blog/feed.xml"}
      xml = FeedsFixtures.rss_fixture(filename)

      {:ok, feeder_ex_feed} = xml |> Feed.parse()

      # We drop timestamps that are not hardcoded. Both `:inserted_at` and
      # `:updated_at` are taken from `DateTime.utc_now()` in `Entry.parse()`.
      feeder_ex_entries =
        Feed.parse_entries(feed, feeder_ex_feed)
        |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

      {:ok, sweet_xml_feed} = xml |> Feed.parse_using_sweet_xml()

      sweet_xml_entries =
        Feed.parse_entries(feed, sweet_xml_feed)
        |> Enum.map(&Map.drop(&1, [:inserted_at, :updated_at]))

      assert length(feeder_ex_entries) > 0
      assert feeder_ex_entries == sweet_xml_entries
      assert feeder_ex_feed.title == sweet_xml_feed.title
    end

    test "1.atom" do
      test_fixture("1.atom")
    end

    test "1.using-namespaces.atom" do
      test_fixture("1.using-namespaces.atom")
    end

    test "1.no-links.atom" do
      test_fixture("1.no-links.atom")
    end

    test "1.rss" do
      test_fixture("1.rss")
    end

    test "1.empty-links.rss" do
      test_fixture("1.empty-links.rss")
    end

    test "1.empty-feed.rss" do
      xml = FeedsFixtures.rss_fixture("1.empty-feed.rss")

      {:ok, feeder_ex_feed} = xml |> Feed.parse()
      {:ok, sweet_xml_feed} = xml |> Feed.parse_using_sweet_xml()

      assert length(feeder_ex_feed.entries) == 0
      assert length(sweet_xml_feed.entries) == 0
      assert feeder_ex_feed.title == sweet_xml_feed.title
    end

    test "1.truncated.rss" do
      xml = FeedsFixtures.rss_fixture("1.truncated.rss")

      {:error, _} = xml |> Feed.parse()
      {:error, {:xml_parsing_failed, _reason}} = xml |> Feed.parse_using_sweet_xml()
    end

    test "unsupported format" do
      assert {:error, :unsupported_format} = Feed.parse_using_sweet_xml("<html />")
    end
  end
end
