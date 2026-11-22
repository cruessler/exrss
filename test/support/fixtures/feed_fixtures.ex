defmodule ExRss.FeedFixtures do
  alias ExRss.{Entry, Feed, Repo}

  @valid_feed_attrs %{title: "some content", url: "https://example.com/some-content"}

  def feed_fixture(%{user_id: user_id} = attrs) do
    attrs = Map.merge(@valid_feed_attrs, attrs)

    %{id: feed_id} =
      feed =
      Feed.changeset(%Feed{user_id: user_id}, attrs)
      |> Repo.insert!()

    entry_fixtures(%{feed_id: feed_id})

    Repo.preload(feed, :entries)
  end

  def entry_fixture(%{feed_id: _} = attrs) do
    id = System.unique_integer([:positive])

    %Entry{
      url: "http://example.com/#{id}",
      title: "Title #{id}",
      read: false,
      posted_at: ~U[2015-12-21 15:08:00Z],
      raw_posted_at: "Mon, 21 Dec 2015 16:08:00 +0100"
    }
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  defp entry_fixtures(attrs) do
    Enum.map(0..5, fn _ -> entry_fixture(attrs) end)
  end

  def rss_fixture_path(name), do: Path.join(["test", "support", "fixtures", "rss", name])
  def rss_fixture(name), do: File.read!(rss_fixture_path(name))
end
