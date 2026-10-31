defmodule ExRss.FeedUpdater do
  alias Ecto.Multi
  alias ExRss.Entry
  alias ExRss.Feed

  # TODO:
  # Find a better name for `raw_feed` (applies to `Feed.parse_entries()`, too).
  def update(feed, raw_feed) do
    new_entries =
      Feed.parse_entries(feed, raw_feed)

    changeset =
      feed
      |> Feed.changeset(%{title: raw_feed.title})

    Multi.new()
    |> Multi.insert_all(:insert_entries, Entry, new_entries, on_conflict: :nothing)
    |> Multi.update(:feed, changeset)
  end
end
