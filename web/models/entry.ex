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
    |> cast(params, [:read])
    |> validate_required([:url])
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

  # For details on available directives, see
  # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  @time_formats [
    # Tue, 03 Jan 2017 14:55:00 +0100
    "%a, %d %b %Y %H:%M:%S %z",
    # Sun, 13 Nov 2016 21:00:00 GMT
    "%a, %d %b %Y %H:%M:%S %Z",
    # 13 Mar 2018 00:00:00 GMT
    "%d %b %Y %H:%M:%S %Z",
    # 2018-08-22T10:07:06.121Z
    "%Y-%m-%dT%H:%M:%S.%LZ",
    # 2019-01-17T00:00:00Z
    "%Y-%m-%dT%H:%M:%SZ",
    # Internet date/time format as specified by RFC 3339
    # See https://tools.ietf.org/html/rfc3339
    # 2018-01-13T19:05:08+00:00
    "%Y-%m-%dT%H:%M:%S%:z"
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

  # If an entry does not have an absolute URL, we merge it with the feed’s URL
  # to get an absolute URL.
  def url_for(feed_url, entry_url) do
    URI.merge(feed_url, entry_url) |> to_string
  end

  def make_url_absolute(entry, feed_url) do
    Map.put(entry, :url, url_for(feed_url, entry.url))
  end
end
