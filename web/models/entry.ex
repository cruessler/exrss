defmodule ExRss.Entry do
  use ExRss.Web, :model

  alias ExRss.Feed

  @derive {Poison.Encoder, only: [:id, :url, :title, :read]}

  schema "entries" do
    belongs_to :feed, Feed

    field :url, :string
    field :title, :string

    field :raw_posted_at, :string
    field :posted_at, :utc_datetime

    field :read, :boolean

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title])
    |> validate_required([:url, :title, :raw_posted_at])
  end

  def parse(entry) do
    now = DateTime.utc_now
    posted_at =
      case parse_time(entry.updated) do
        {:ok, parsed_time} -> parsed_time
        {:error, _} -> nil
      end

    %{title: entry.title,
      url: entry.link,
      raw_posted_at: entry.updated,
      posted_at: posted_at,
      inserted_at: now,
      updated_at: now}
  end

  def parse_time(time) do
    # Tue, 03 Jan 2017 14:55:00 +0100
    case Timex.parse(time, "%a, %d %b %Y %H:%M:%S %z", :strftime) do
      {:ok, posted_at} ->
        {:ok, posted_at |> Timex.Timezone.convert("Etc/UTC")}

      {:error, _} = error ->
        error
    end
  end
end
