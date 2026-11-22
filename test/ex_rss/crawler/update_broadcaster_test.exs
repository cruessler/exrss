defmodule ExRss.Crawler.UpdateBroadcasterTest do
  use ExRss.DataCase

  import ExRss.{AccountsFixtures, FeedFixtures}

  alias ExRss.Crawler.UpdateBroadcaster
  alias ExRss.Feed
  alias Phoenix.Socket.Broadcast

  test "broadcasts update when there's an unread and a read entry" do
    feed = empty_feed_fixture()
    feed_id = feed.id

    _read_entry = entry_fixture(%{feed_id: feed_id, read: true})
    unread_entry = entry_fixture(%{feed_id: feed_id, read: false})
    unread_entry_id = unread_entry.id
    topic = "user:#{feed.user_id}"

    ExRssWeb.Endpoint.subscribe(topic)

    assert {:ok, nil} = UpdateBroadcaster.broadcast_update(feed)

    assert_receive %Broadcast{
      topic: ^topic,
      event: "unread_entries",
      payload: %{
        feed: %{
          id: ^feed_id,
          unread_entries_count: 1,
          read_entries_count: 1,
          entries: [
            %{id: ^unread_entry_id}
          ]
        }
      }
    }
  end

  test "broadcasts update when there's only read entries" do
    feed = empty_feed_fixture()
    feed_id = feed.id

    0..5
    |> Enum.map(fn _ ->
      _read_entry = entry_fixture(%{feed_id: feed_id, read: true})
    end)

    topic = "user:#{feed.user_id}"

    ExRssWeb.Endpoint.subscribe(topic)

    assert {:ok, nil} = UpdateBroadcaster.broadcast_update(feed)

    assert_receive %Broadcast{
      topic: ^topic,
      event: "unread_entries",
      payload: %{
        feed: %{
          id: ^feed_id,
          unread_entries_count: 0,
          read_entries_count: 6,
          entries: []
        }
      }
    }
  end

  test "broadcasts update when feed has no entries" do
    feed = empty_feed_fixture()
    feed_id = feed.id

    topic = "user:#{feed.user_id}"

    ExRssWeb.Endpoint.subscribe(topic)

    assert {:ok, nil} = UpdateBroadcaster.broadcast_update(feed)

    assert_receive %Broadcast{
      topic: ^topic,
      event: "unread_entries",
      payload: %{
        feed: %{
          id: ^feed_id,
          unread_entries_count: 0,
          read_entries_count: 0,
          entries: []
        }
      }
    }
  end

  defp empty_feed_fixture do
    user = user_fixture()

    Feed.changeset(%Feed{user_id: user.id, url: "https://example.com/blog"})
    |> Repo.insert!()
  end
end
