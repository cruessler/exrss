defmodule ExRss.FeedFixtures do
  alias ExRss.{Entry, Feed, Repo}

  @valid_feed_attrs %{title: "some content", url: "https://example.com/some-content"}

  def feed_fixture(%{user_id: user_id}) do
    %{id: feed_id} =
      feed =
      Feed.changeset(%Feed{user_id: user_id}, @valid_feed_attrs)
      |> Repo.insert!()

    {6, nil} = entry_fixtures(%{feed_id: feed_id})

    Repo.preload(feed, :entries)
  end

  defp entry_fixtures(%{feed_id: feed_id}) do
    entries =
      0..5
      |> Enum.map(fn _ ->
        unique_integer = System.unique_integer()

        %{
          link: "http://example.com/#{unique_integer}",
          title: "Title #{unique_integer}",
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
