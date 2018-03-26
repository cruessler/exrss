defmodule ExRss.Entry do
  use ExRss.Web, :model

  alias ExRss.Feed

  @derive {Poison.Encoder, only: [:id, :url, :title, :read, :posted_at]}

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
    |> cast(params, [:url, :title, :read, :raw_posted_at])
    |> validate_required([:url, :title])
    |> assoc_constraint(:feed)
    |> unique_constraint(:url, name: :entries_feed_id_url_index)
  end

  def parse(entry) do
    now = DateTime.utc_now()

    posted_at =
      case parse_time(entry.updated) do
        {:ok, parsed_time} -> parsed_time
        {:error, _} -> nil
      end

    %{
      title: entry.title,
      url: entry.link,
      raw_posted_at: entry.updated,
      posted_at: posted_at,
      read: false,
      inserted_at: now,
      updated_at: now
    }
  end

  @time_formats [
    # Tue, 03 Jan 2017 14:55:00 +0100
    "%a, %d %b %Y %H:%M:%S %z",
    # Sun, 13 Nov 2016 21:00:00 GMT
    "%a, %d %b %Y %H:%M:%S %Z"
  ]

  def parse_time(time) do
    parse_time(time, @time_formats)
  end

  def parse_time(time, formats) do
    case formats do
      [] ->
        {:error, :no_format_found}

      [head | tail] ->
        case Timex.parse(time, head, :strftime) do
          {:ok, posted_at} ->
            {:ok, posted_at |> Timex.Timezone.convert("Etc/UTC")}

          {:error, _} ->
            parse_time(time, tail)
        end
    end
  end
end
