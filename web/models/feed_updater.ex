defmodule ExRss.FeedUpdater do
  alias Ecto.Multi
  alias ExRss.Entry
  alias ExRss.Feed

  def update(feed, raw_feed) do
    new_entries =
      for entry <- raw_feed.entries do
        entry
        |> Entry.parse()
        |> Map.put(:feed_id, feed.id)
      end

    changeset =
      feed
      |> Feed.changeset(%{title: raw_feed.title})

    Multi.new()
    |> Multi.insert_all(:insert_entries, Entry, new_entries, on_conflict: :nothing)
    |> Multi.update(:feed, changeset)
  end
end
