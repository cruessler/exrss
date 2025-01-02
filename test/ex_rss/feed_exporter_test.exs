defmodule ExRss.FeedExporterTest do
  use ExRss.DataCase

  import ExRss.AccountsFixtures
  import ExRss.FeedFixtures

  test "exports feed" do
    %{id: user_id} = user_fixture()
    feed = feed_fixture(%{user_id: user_id})

    assert %{} = feed
    assert length(feed.entries) == 6
  end
end
