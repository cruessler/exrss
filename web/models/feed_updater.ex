defmodule ExRss.FeedUpdater do
  require Ecto.Query
  require Logger

  alias Ecto.Multi
  alias ExRss.Entry
  alias ExRss.Feed
  alias ExRss.Repo

  def update(feed, raw_feed) do
    new_entries =
      raw_feed.entries
      |> Enum.map(fn entry -> Map.put(Entry.parse(entry), :feed_id, feed.id) end)

    Multi.new
    |> Multi.insert_all(:insert_entries, Entry, new_entries, on_conflict: :nothing)
    |> Multi.update_all(
      :update_feed,
      Ecto.Query.from(f in Feed, where: f.id == ^feed.id),
      set: [url: raw_feed.url, title: raw_feed.title, updated_at: DateTime.utc_now])
    |> Repo.transaction

    Logger.debug "Updated feed #{feed.title}"

    {:ok, feed}
  end
end
