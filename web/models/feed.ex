defmodule ExRss.Feed do
  use ExRss.Web, :model

  alias ExRss.Entry

  schema "feeds" do
    field :title, :string
    field :url, :string

    has_many :entries, Entry

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url])
    |> validate_required([:title, :url])
  end
end
