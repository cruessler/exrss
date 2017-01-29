defmodule ExRss.Feed do
  use ExRss.Web, :model

  alias Ecto.Changeset
  alias ExRss.Entry
  alias ExRss.User
  alias Timex.Duration

  @base_timeout Duration.from_minutes(15) |> Duration.to_milliseconds
  @max_timeout Duration.from_days(1) |> Duration.to_milliseconds

  schema "feeds" do
    field :title, :string
    field :url, :string
    field :next_update_at, :utc_datetime
    field :retries, :integer

    belongs_to :user, User

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

  def schedule_update_on_error(changeset) do
    retries = Changeset.get_field(changeset, :retries)

    changeset
    |> schedule_update
    |> Changeset.put_change(:retries, retries + 1)
  end

  def schedule_update_on_success(changeset) do
    changeset
    |> Changeset.put_change(:retries, 0)
    |> schedule_update
  end

  defp schedule_update(changeset) do
    retries = Changeset.get_field(changeset, :retries)

    new_timeout =
      :math.pow(1.5, retries) * @base_timeout
      |> round
      |> min(@max_timeout)
      |> Duration.from_milliseconds

    next_update_at =
      changeset
      |> Changeset.get_field(:next_update_at)
      |> later(DateTime.utc_now)
      |> Timex.add(new_timeout)

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
