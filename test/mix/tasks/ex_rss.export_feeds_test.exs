defmodule Mix.Tasks.ExRss.ExportFeedsTest do
  use ExRss.DataCase, async: false

  import ExRss.{AccountsFixtures, FeedFixtures}

  alias Mix.Tasks.ExRss.ExportFeeds

  @tag :tmp_dir
  test "the task works", %{tmp_dir: tmp_dir} do
    user = user_fixture()
    feed = feed_fixture(%{user_id: user.id})
    filename = Path.join(tmp_dir, "feeds.opml")

    ExportFeeds.run([to_string(user.id), filename])

    opml = File.read!(filename)
    assert opml =~ ~s(xmlUrl="#{feed.url}")

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

    assert !File.exists?(filename)
  end

  test "shows usage when arguments are missing" do
    assert_raise Mix.Error, "Usage: mix ex_rss.export_feeds <USER_ID> <FILENAME>", fn ->
      ExportFeeds.run([])
    end
  end
end
