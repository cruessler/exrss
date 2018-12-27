defmodule ExRss.FeedTest do
  use ExRss.ModelCase

  alias Ecto.Changeset
  alias ExRss.{Entry, Feed, User}
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

  @timeout Duration.from_minutes(15) |> Duration.to_milliseconds()
  @max_timeout Duration.from_days(1) |> Duration.to_milliseconds()

  test "schedule_update_on_error" do
    changeset =
      %Feed{retries: 0, next_update_at: DateTime.utc_now()}
      |> Changeset.change()
      |> Feed.schedule_update_on_error()

    diff = Timex.diff(changeset.changes.next_update_at, DateTime.utc_now(), :milliseconds)

    assert %{retries: 1} = changeset.changes
    assert_in_delta diff, @timeout, 100

    changeset =
      changeset
      |> Feed.schedule_update_on_error()

    assert %{retries: 2} = changeset.changes
    assert Timex.compare(changeset.changes.next_update_at, DateTime.utc_now()) == 1
  end

  test "schedule_update has a maximum timeout" do
    changeset =
      %Feed{retries: 20, next_update_at: DateTime.utc_now()}
      |> Changeset.change()
      |> Feed.schedule_update_on_error()

    diff = Timex.diff(changeset.changes.next_update_at, DateTime.utc_now(), :milliseconds)

    # We cannot check for equality becase Duration.from_milliseconds in
    # Feed.schedule_update might yield small rounding errors.
    assert_in_delta diff, @max_timeout, 10
  end

  test "schedule_update schedules update in the future" do
    next_update_at =
      DateTime.utc_now()
      |> Timex.subtract(Duration.from_days(2))

    changeset =
      %Feed{retries: 20, next_update_at: next_update_at}
      |> Changeset.change()
      |> Feed.schedule_update_on_error()

    diff = Timex.diff(changeset.changes.next_update_at, DateTime.utc_now(), :milliseconds)

    # We cannot check for equality becase Duration.from_milliseconds in
    # Feed.schedule_update might yield small rounding errors.
    assert_in_delta diff, @max_timeout, 10
  end

  test "schedule_update_on_success" do
    changeset =
      %Feed{retries: 0, next_update_at: DateTime.utc_now()}
      |> Changeset.change()
      |> Feed.schedule_update_on_success()

    diff = Timex.diff(changeset.changes.next_update_at, DateTime.utc_now(), :milliseconds)

    assert Changeset.get_field(changeset, :retries) == 0
    assert_in_delta diff, @timeout, 100
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

    for e <- Changeset.get_field(changeset, :entries), do: assert e.read == true
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
end
