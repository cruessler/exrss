defmodule ExRss.FeedUpdaterTest do
  use ExRss.ModelCase

  alias Ecto.Multi
  alias ExRss.Feed
  alias ExRss.FeedUpdater

  test "updates entries" do
    feed = %Feed{id: 1, title: "This is a title", url: "http://example.com", user_id: 1}

    raw_feed = %{
      title: "This is a title",
      entries: [
        %{
          title: "This is a title",
          link: "http://example.com/posts/1.html",
          updated: DateTime.utc_now() |> DateTime.to_string()
        },
        %{
          title: "This is a title",
          link: "/posts/2.html",
          updated: DateTime.utc_now() |> DateTime.to_string()
        }
      ]
    }

    multi = FeedUpdater.update(feed, raw_feed)

    assert [
             {:insert_entries, {:insert_all, ExRss.Entry, [first, second], _}},
             {:feed, {:update, feed_changeset, []}}
           ] = Multi.to_list(multi)

    assert first.feed_id == feed.id
    assert first.url == "http://example.com/posts/1.html"
    assert second.url == "http://example.com/posts/2.html"
    assert feed_changeset.valid?
  end
end
