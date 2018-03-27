defmodule ExRss.DateParserTest do
  use ExRss.ModelCase

  import Ecto.Query

  alias ExRss.DateParser
  alias ExRss.{Entry, Feed, User}

  setup do
    Repo.insert!(%User{id: 1, email: "jane@doe.com"})
    Repo.insert!(%Feed{id: 1, user_id: 1, title: "Title", url: "http://example.com"})

    Repo.insert!(%Entry{
      id: 1,
      url: "http://example.com/1",
      title: "Title",
      raw_posted_at: "Sun, 21 Dec 2014 16:08:00 +0100",
      read: false,
      feed_id: 1
    })

    Repo.insert!(%Entry{
      id: 2,
      url: "http://example.com/2",
      title: "Title 2",
      raw_posted_at: "Sun, 21 Dec 2015 16:08:00 +0100",
      read: false,
      feed_id: 1
    })

    :ok
  end

  test "clears and parses publication dates" do
    DateParser.clear_parsed()

    assert with_empty_publication_date() == 2

    assert DateParser.list_unparsed(10) |> Enum.count() == 2

    DateParser.parse()

    assert with_empty_publication_date() == 0

    DateParser.clear_parsed()

    assert with_empty_publication_date() == 2
  end

  def with_empty_publication_date() do
    from(e in Entry, select: count(e.id), where: is_nil(e.posted_at))
    |> Repo.one()
  end
end
