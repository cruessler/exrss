defmodule ExRss.Feed do
  use ExRssWeb, :model

  alias Ecto.Changeset
  alias ExRss.Entry
  alias ExRss.User
  alias Timex.Duration

  @base_timeout Duration.from_minutes(60) |> Duration.to_seconds()
  @max_timeout Duration.from_days(1) |> Duration.to_seconds() |> round

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :url,
             :entries,
             :unread_entries_count,
             :read_entries_count,
             :has_error,
             :position,
             :last_successful_update_at
           ]}

  @timestamps_opts [type: :utc_datetime]

  schema "feeds" do
    field :title, :string
    field :url, :string
    field :next_update_at, :utc_datetime
    field :last_successful_update_at, :utc_datetime
    field :retries, :integer

    field :unread_entries_count, :integer, virtual: true
    field :read_entries_count, :integer, virtual: true
    field :has_error, :boolean, virtual: true
    field :newest_unread_entry_posted_at, :utc_datetime, virtual: true
    field :position, :integer

    belongs_to :user, User

    has_many :entries, Entry

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :position])
    |> validate_required([:user_id, :title, :url])
    |> assoc_constraint(:user)
    |> unique_constraint(:url)
  end

  def api_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:position])
    |> validate_required([:user_id, :title, :url])
    |> assoc_constraint(:user)
    |> unique_constraint(:url)
  end

  def parse(xml) do
    try do
      FeederEx.parse(xml)
    catch
      :throw, value ->
        {:error, value}
    else
      {:ok, raw_feed, _} ->
        {:ok, raw_feed}

      {:fatal_error, _, error, _, _} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end

  def mark_as_read(feed) do
    entries = for e <- feed.entries, do: Changeset.change(e, read: true)

    feed
    |> Changeset.change([])
    |> Changeset.put_assoc(:entries, entries)
  end

  def schedule_update_on_error(changeset, now \\ now_with_seconds_precision()) do
    retries = Changeset.get_field(changeset, :retries)

    changeset
    |> schedule_update(now)
    |> Changeset.put_change(:retries, retries + 1)
  end

  def schedule_update_on_success(changeset, now \\ now_with_seconds_precision()) do
    changeset
    |> Changeset.put_change(:retries, 0)
    |> Changeset.put_change(:last_successful_update_at, now)
    |> schedule_update(now)
  end

  defp now_with_seconds_precision do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  defp schedule_update(changeset, now) do
    retries = Changeset.get_field(changeset, :retries)

    new_timeout =
      try do
        (:math.pow(1.5, retries) * @base_timeout)
        |> round
        |> min(@max_timeout)
      rescue
        # `:math.pow` throws an `ArithmeticError` once `retries` crosses a
        # certain threshold.
        ArithmeticError -> @max_timeout
      end

    next_update_at =
      changeset
      |> Changeset.get_field(:next_update_at)
      |> later(now)
      |> Timex.shift(seconds: new_timeout)
      |> DateTime.truncate(:second)

    changeset
    |> Changeset.put_change(:next_update_at, next_update_at)
  end

  defp later(a, b) do
    case Timex.compare(a, b) do
      -1 -> b
      0 -> a
      1 -> a
    end
  end
end
