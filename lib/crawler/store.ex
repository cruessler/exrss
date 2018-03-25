defmodule ExRss.Crawler.Store do
  import Ecto.Query

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
end
