defmodule ExRssWeb.FeedLive.Index do
  import Ecto.Query

  use ExRssWeb, :live_view

  alias ExRss.{Entry, Feed, Repo, User}
  alias ExRss.{FeedAdder, FeedRemover}

  def mount(
        _params,
        %{"api_token" => api_token, "current_user" => current_user} = _session,
        socket
      ) do
    ExRssWeb.Endpoint.subscribe("user:#{current_user.id}")

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:api_token, api_token)
      |> assign(:form, to_form(%{}))
      |> assign(:discovered_feeds, [])
      |> assign_feeds()

    {:ok, socket}
  end

  def assign_feeds(socket, opts \\ []) do
    user_id = socket.assigns.current_user.id

    oldest_unread_entry = User.oldest_unread_entry(user_id)

    current_user = Repo.get!(User, socket.assigns.current_user.id)

    feeds_of_current_user = current_user |> Ecto.assoc(:feeds)

    feeds_with_counts =
      from(
        f in feeds_of_current_user,
        join: e in Entry,
        on: f.id == e.feed_id,
        group_by: f.id,
        order_by: [
          desc_nulls_last: f.position,
          desc_nulls_last: selected_as(:newest_unread_entry_posted_at)
        ],
        select: %{
          f
          | unread_entries_count: filter(count(e.id), e.read == false),
            read_entries_count: filter(count(e.id), e.read == true),
            newest_unread_entry_posted_at:
              filter(max(e.posted_at), e.read == false)
              |> selected_as(:newest_unread_entry_posted_at),
            has_error: f.retries > 0
        }
      )

    feeds =
      feeds_with_counts
      |> Repo.all()
      |> Repo.preload(
        entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
      )

    number_of_unread_entries =
      feeds |> List.foldl(0, fn feed, acc -> feed.unread_entries_count + acc end)

    number_of_read_entries =
      feeds |> List.foldl(0, fn feed, acc -> feed.read_entries_count + acc end)

    number_of_feeds_with_error =
      feeds |> Enum.count(& &1.has_error)

    socket
    |> assign(:oldest_unread_entry, oldest_unread_entry)
    |> assign(:number_of_unread_entries, number_of_unread_entries)
    |> assign(:number_of_read_entries, number_of_read_entries)
    |> assign(:number_of_feeds_with_error, number_of_feeds_with_error)
    |> stream(:feeds, feeds, opts)
  end

  def handle_event("mark_as_read", %{"entry-id" => entry_id}, socket) do
    current_user =
      Repo.get!(User, socket.assigns.current_user.id)

    changeset =
      current_user
      |> Ecto.assoc(:entries)
      |> Repo.get!(entry_id)
      |> Entry.changeset(%{"read" => true})

    case Repo.update(changeset) do
      {:ok, _entry} ->
        {:noreply, assign_feeds(socket, reset: true)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("mark_as_read", %{"feed-id" => feed_id}, socket) do
    current_user =
      Repo.get!(User, socket.assigns.current_user.id)

    changeset =
      current_user
      |> Ecto.assoc(:feeds)
      |> Repo.get!(feed_id)
      |> Repo.preload(:entries)
      |> Feed.mark_as_read()

    case Repo.update(changeset) do
      {:ok, _feed} ->
        {:noreply, assign_feeds(socket, reset: true)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("pin_feed", %{"feed-id" => feed_id}, socket) do
    update_feed_position(feed_id, 0, socket)
  end

  def handle_event("unpin_feed", %{"feed-id" => feed_id}, socket) do
    update_feed_position(feed_id, nil, socket)
  end

  def handle_event("remove_feed", %{"feed-id" => feed_id}, socket) do
    current_user = Repo.get!(User, socket.assigns.current_user.id)

    multi =
      FeedRemover.remove_feed(current_user, %{"id" => feed_id})

    case Repo.transaction(multi) do
      {:ok, %{feed: _}} ->
        socket =
          socket
          |> assign_feeds(reset: true)

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("discover_feeds", %{"feed_url" => feed_url}, socket) do
    case FeedAdder.discover_feeds(feed_url) do
      {:ok, feeds} ->
        {:noreply, assign(socket, :discovered_feeds, feeds)}

      {:error, _error} ->
        {:noreply, socket}
    end
  end

  def handle_event("add_feed", feed_params, socket) do
    multi =
      Repo.get!(User, socket.assigns.current_user.id)
      |> FeedAdder.add_feed(feed_params)

    case Repo.transaction(multi) do
      {:ok, %{feed: _new_feed}} ->
        {:noreply, assign(socket, :discovered_feeds, [])}

      {:error, _error} ->
        {:noreply, socket}
    end
  end

  def handle_info(%{event: "unread_entries"}, socket) do
    {:noreply, assign_feeds(socket, reset: true)}
  end

  def update_feed_position(feed_id, position, socket) do
    changeset =
      Repo.get!(User, socket.assigns.current_user.id)
      |> Ecto.assoc(:feeds)
      |> Repo.get!(feed_id)
      |> Feed.changeset(%{"position" => position})

    case Repo.update(changeset) do
      {:ok, _feed} ->
        {:noreply, assign_feeds(socket, reset: true)}

      _ ->
        {:noreply, socket}
    end
  end

  attr :entry, Entry, required: true

  def entry(assigns) do
    ~H"""
    <ul class="flex flex-col">
      <li class="flex flex-col md:flex-row">
        <div class="flex flex-col">
          <a href={@entry.url} target="_blank">{@entry.title}</a>
          <span>{format_timestamp_relative_to_now(@entry.posted_at)}</span>
        </div>

        <div class="md:shrink-0 flex self-start mt-1 ml-auto space-x-4">
          <a
            href={@entry.url}
            target="_blank"
            aria-label={"View entry #{@entry.title}"}
            phx-click="mark_as_read"
            phx-value-entry-id={@entry.id}
          >
            <.icon name="hero-arrow-top-right-on-square-solid" />
          </a>
          <button aria-label="Mark as read" phx-click="mark_as_read" phx-value-entry-id={@entry.id}>
            <.icon name="hero-check-circle-solid" />
          </button>
        </div>
      </li>
    </ul>
    """
  end

  attr :entries, :list, required: true

  def entries(assigns) do
    if length(assigns.entries) > 5 do
      assigns =
        assigns
        |> assign(:head_entries, Enum.take(assigns.entries, 2))
        |> assign(:number_of_entries_not_shown, length(assigns.entries) - 4)
        |> assign(:tail_entries, Enum.take(assigns.entries, -2))

      ~H"""
      <ul class="mb-6 flex flex-col space-y-4">
        <li :for={entry <- @head_entries}>
          <.entry entry={entry} />
        </li>
        <div>{@number_of_entries_not_shown} entries not shown</div>
        <li :for={entry <- @tail_entries}>
          <.entry entry={entry} />
        </li>
      </ul>
      """
    else
      ~H"""
      <ul class="mb-6 flex flex-col space-y-4">
        <li :for={entry <- @entries}>
          <.entry entry={entry} />
        </li>
      </ul>
      """
    end
  end

  def format_timestamp_relative_to_now(updated_at, attrs \\ []) do
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

  def format_frequency(%{seconds: seconds, posts: posts}) do
    duration =
      if seconds < 2 * 86400 do
        "#{(seconds / 3600) |> round} hours"
      else
        "#{(seconds / 86400) |> round} days"
      end

    "#{posts} posts in #{duration}"
  end
end
