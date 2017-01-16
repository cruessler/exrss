defmodule ExRss.FeedUpdater do
  require Ecto.Query
  require Logger

  alias Ecto.Changeset
  alias Ecto.Multi
  alias ExRss.Entry

  def update(feed, raw_feed) do
    new_entries =
      raw_feed.entries
      |> Enum.map(fn entry -> Map.put(Entry.parse(entry), :feed_id, feed.id) end)

    changeset =
      feed
      |> Changeset.change(%{url: raw_feed.url, title: raw_feed.title, updated_at: DateTime.utc_now})

    Multi.new
    |> Multi.insert_all(:insert_entries, Entry, new_entries, on_conflict: :nothing)
    |> Multi.update(:feed, changeset)
  end
end
