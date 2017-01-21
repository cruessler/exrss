defmodule ExRss.Entry do
  use ExRss.Web, :model

  alias ExRss.Feed

  schema "entries" do
    belongs_to :feed, Feed

    field :url, :string
    field :title, :string

    field :posted_at, :utc_datetime

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title])
    |> validate_required([:url, :title])
  end

  def parse(entry) do
    now = DateTime.utc_now
    posted_at = parse_time(entry.updated)

    %{title: entry.title,
      url: entry.link,
      posted_at: posted_at,
      inserted_at: now,
      updated_at: now}
  end

  def parse_time(time) do
    # Tue, 03 Jan 2017 14:55:00 +0100
    {:ok, posted_at} =
      Timex.parse(time, "%a, %d %b %Y %H:%M:%S %z", :strftime)

    posted_at |> Timex.Timezone.convert("Etc/UTC")
  end
end
