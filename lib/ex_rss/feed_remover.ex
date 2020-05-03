defmodule ExRss.FeedRemover do
  alias Ecto.Multi
  alias ExRss.Repo

  def remove_feed(user, %{"id" => feed_id}) do
    feed =
      user
      |> Ecto.assoc(:feeds)
      |> Repo.get!(feed_id)

    Multi.new()
    |> Multi.delete(:feed, feed)
    |> Multi.run(:notify_queue, fn _repo, %{feed: feed} ->
      GenServer.cast(ExRss.Crawler.Queue, {:remove_feed, feed})

      {:ok, nil}
    end)
  end
end
