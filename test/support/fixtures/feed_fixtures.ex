defmodule ExRss.FeedFixtures do
  alias ExRss.{Entry, Feed, Repo}

  @valid_feed_attrs %{title: "some content", url: "https://example.com/some-content"}

  def feed_fixture(%{user_id: user_id} = attrs) do
    attrs = Map.merge(@valid_feed_attrs, attrs)

    %{id: feed_id} =
      feed =
      Feed.changeset(%Feed{user_id: user_id}, attrs)
      |> Repo.insert!()

    {6, nil} = entry_fixtures(%{feed_id: feed_id})

    Repo.preload(feed, :entries)
  end

  defp entry_fixtures(%{feed_id: feed_id}) do
    entries =
      0..5
      |> Enum.map(fn _ ->
        id = System.unique_integer([:positive])

        %{
          link: "http://example.com/#{id}",
          title: "Title #{id}",
          # TODO
          # Use random date instead.
          updated: "Sun, 21 Dec 2015 16:08:00 +0100",
          read: false
        }
        |> Entry.parse()
        |> Map.put(:feed_id, feed_id)
      end)

    Repo.insert_all(Entry, entries)
  end
end
