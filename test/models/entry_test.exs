defmodule ExRss.EntryTest do
  use ExRss.ModelCase

  alias Ecto.Changeset
  alias ExRss.Entry

  test "validates presence of title" do
    changeset = Entry.changeset(%Entry{}, %{title: nil})

    refute changeset.valid?

    changeset = Entry.changeset(%Entry{}, %{title: ""})

    refute changeset.valid?
  end

  test "parses time" do
    assert {:ok, _} = Entry.parse_time("Tue, 03 Jan 2017 14:55:00 +0100")
    assert {:ok, _} = Entry.parse_time("Sun, 13 Nov 2016 21:00:00 GMT")
  end
end
