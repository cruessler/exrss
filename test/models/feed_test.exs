defmodule ExRss.FeedTest do
  use ExRss.ModelCase

  alias Ecto.Changeset
  alias ExRss.Feed
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
end
