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
end
