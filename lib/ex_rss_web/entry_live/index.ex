defmodule ExRssWeb.EntryLive.Index do
  import Ecto.Query

  use ExRssWeb, :live_view

  alias ExRss.{Entry, Feed, Repo, User}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    ExRssWeb.Endpoint.subscribe("user:#{current_user.id}")

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:entries, [])

    {:ok, socket}
  end

  defp assign_entries(socket) do
    current_user = Repo.get!(User, socket.assigns.current_user.id)

    entries_of_current_user = current_user |> Ecto.assoc(:entries)

    entries =
      from(
        e in entries_of_current_user,
        join: f in Feed,
        on: f.id == e.feed_id,
        where: e.read == false,
        order_by: [
          desc_nulls_last: e.posted_at
        ],
        select: e,
        preload: :feed
      )
      |> Repo.all()

    number_of_unread_entries =
      entries |> Enum.count()

    socket
    |> assign(:page_title, "#{number_of_unread_entries} unread")
    |> assign(:number_of_unread_entries, number_of_unread_entries)
    |> assign(:entries, entries)
  end

  @impl true
  def handle_event("mark_as_read", %{"entry-id" => entry_id}, socket) do
    # TODO:
    # There's some duplication with `feed_live/index.ex`. Potentially extract
    # `Entry.mark_as_read!`.
    current_user =
      Repo.get!(User, socket.assigns.current_user.id)

    changeset =
      current_user
      |> Ecto.assoc(:entries)
      |> Repo.get!(entry_id)
      |> Entry.changeset(%{"read" => true})

    socket =
      case Repo.update(changeset) do
        {:ok, entry} ->
          socket
          |> assign_entries()
          |> put_flash(:info, "Entry “#{entry.title}” marked as read")

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    socket =
      socket
      |> assign_entries()

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "unread_entries"}, socket) do
    {:noreply, assign_entries(socket)}
  end

  # TODO:
  # The formatting-related functions were taken from `feed_live/index.ex`.
  # Deduplicate.
  def format_timestamp_relative_to_now(updated_at, attrs \\ [])

  def format_timestamp_relative_to_now(updated_at, attrs)
      when is_binary(updated_at) do
    {default, _attrs} = Keyword.pop(attrs, :default, "n/a")

    case Entry.parse_time(updated_at) do
      {:ok, updated_at} -> format_timestamp_relative_to_now(updated_at, attrs)
      _ -> default
    end
  end

  def format_timestamp_relative_to_now(updated_at, attrs) do
    {default, _attrs} = Keyword.pop(attrs, :default, "n/a")

    with interval = %Timex.Interval{} <- Timex.Interval.new(from: updated_at, until: Timex.now()) do
      duration =
        Timex.Interval.duration(interval, :duration)

      duration_in_days =
        Timex.Duration.to_days(duration)

      if duration_in_days > 5 do
        format_datetime(updated_at, default)
      else
        # There is also a relative formatter provided by Timex in case the code
        # below needs to be changed or improved.
        #
        # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Relative.html#summary
        formatted_duration =
          duration
          |> Timex.Duration.to_minutes(truncate: true)
          |> Timex.Duration.from_minutes()
          |> Timex.format_duration(:humanized)

        "#{formatted_duration} ago"
      end
    else
      {:error, :invalid_until} ->
        format_datetime(updated_at, default)

      _ ->
        default
    end
  end

  defp format_datetime(datetime, default) do
    case Timex.format(
           datetime,
           "%B %d, %Y, %k:%M",
           :strftime
         ) do
      {:ok, formatted_datetime} ->
        formatted_datetime

      _ ->
        default
    end
  end
end
