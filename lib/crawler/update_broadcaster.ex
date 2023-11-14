defmodule ExRss.Crawler.UpdateBroadcaster do
  alias ExRss.Entry
  alias ExRss.Feed

  import Ecto.Query, only: [from: 2]

  def broadcast_update(feed) do
    unread_entries =
      from(
        e in Entry,
        where: e.read == false
      )

    feed_with_unread_entries =
      from(
        f in Feed,
        join: e in Entry,
        on: f.id == e.feed_id,
        group_by: f.id,
        select: %{
          f
          | unread_entries_count: filter(count(e.id), e.read == false),
            read_entries_count: filter(count(e.id), e.read == true),
            has_error: f.retries > 0
        }
      )
      |> ExRss.Repo.get(feed.id)
      |> ExRss.Repo.preload(entries: unread_entries)
      |> Map.put(:last_successful_update_at, feed.last_successful_update_at)

    if feed_with_unread_entries.unread_entries_count > 0 do
      ExRssWeb.Endpoint.broadcast!("user:#{feed.user_id}", "unread_entries", %{
        feed: feed_with_unread_entries
      })
    end

    {:ok, nil}
  end
end
