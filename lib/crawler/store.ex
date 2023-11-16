defmodule ExRss.Crawler.Store do
  import Ecto.Query

  alias Ecto.Changeset

  alias ExRss.Feed
  alias ExRss.Repo

  def load() do
    from(Feed, order_by: [asc: :next_update_at])
    |> Repo.all()
    |> Enum.map(fn
      %{next_update_at: nil} = feed -> %{feed | next_update_at: DateTime.utc_now()}
      feed -> feed
    end)
  end

  def update_on_success!(feed) do
    feed
    |> Changeset.change()
    |> Feed.schedule_update_on_success()
    |> Repo.update!()
  end

  def update_on_error!(feed) do
    feed
    |> Changeset.change()
    |> Feed.schedule_update_on_error()
    |> Repo.update!()
  end
end
