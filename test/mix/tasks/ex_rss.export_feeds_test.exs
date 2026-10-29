defmodule Mix.Tasks.ExRss.ExportFeedsTest do
  use ExRss.DataCase, async: false

  import ExRss.{AccountsFixtures, FeedFixtures}

  alias Mix.Tasks.ExRss.ExportFeeds

  @tag :tmp_dir
  test "a user's feeds are exported", %{tmp_dir: tmp_dir} do
    user = user_fixture()
    feed = feed_fixture(%{user_id: user.id})
    filename = Path.join(tmp_dir, "feeds.opml")

    ExportFeeds.run([to_string(user.id), filename])

    opml = File.read!(filename)
    assert opml =~ ~s(xmlUrl="#{feed.url}")

    assert_received {:mix_shell, :info, ["Exported 1 feeds"]}
  end

  @tag :tmp_dir
  test "only requested user's feeds are exported", %{tmp_dir: tmp_dir} do
    first_user = user_fixture()
    second_user = user_fixture()
    first_feed = feed_fixture(%{user_id: first_user.id})
    second_feed = feed_fixture(%{user_id: second_user.id, title: "second feed"})
    filename = Path.join(tmp_dir, "feeds.opml")

    ExportFeeds.run([to_string(first_user.id), filename])

    opml = File.read!(filename)
    assert opml =~ ~s(text="#{first_feed.title}")
    refute opml =~ ~s(text="#{second_feed.title}")

    assert_received {:mix_shell, :info, ["Exported 1 feeds"]}
  end

  test "raises when user id is not an integer" do
    assert_raise Mix.Error, "12.5 could not be parsed as a user id", fn ->
      ExportFeeds.run(["12.5", "feeds.opml"])
    end
  end

  test "raises when user can't be found" do
    assert_raise Mix.Error, "Could not load user ##{12}", fn ->
      ExportFeeds.run(["12", "feeds.opml"])
    end
  end

  @tag :tmp_dir
  test "raises when user doesn't have feeds", %{tmp_dir: tmp_dir} do
    user = user_fixture()
    filename = Path.join(tmp_dir, "feeds.opml")

    assert_raise Mix.Error, "User ##{user.id} has no feeds to export", fn ->
      ExportFeeds.run([to_string(user.id), filename])
    end

    refute File.exists?(filename)
  end

  test "shows usage when arguments are missing" do
    assert_raise Mix.Error, "Usage: mix ex_rss.export_feeds <USER_ID> <FILENAME>", fn ->
      ExportFeeds.run([])
    end
  end
end
