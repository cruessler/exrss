defmodule ExRssWeb.FeedLive.Index do
  import Ecto.Query

  use ExRssWeb, :live_view

  alias ExRss.{Entry, Feed, Repo, User}

  def mount(
        _params,
        %{"api_token" => api_token, "current_user" => current_user} = _session,
        socket
      ) do
    oldest_unread_entry = User.oldest_unread_entry(current_user.id)

    current_user = Repo.get!(User, current_user.id)

    feeds_of_current_user = current_user |> Ecto.assoc(:feeds)

    feeds_with_counts =
      from(
        f in feeds_of_current_user,
        join: e in Entry,
        on: f.id == e.feed_id,
        group_by: f.id,
        order_by: [desc_nulls_last: f.position],
        select: %{
          f
          | unread_entries_count: filter(count(e.id), e.read == false),
            read_entries_count: filter(count(e.id), e.read == true),
            has_error: f.retries > 0
        }
      )

    feeds =
      feeds_with_counts
      |> Repo.all()
      |> Repo.preload(
        entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
      )

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:api_token, api_token)
      |> assign(:oldest_unread_entry, oldest_unread_entry)
      |> stream(:feeds, feeds)

    {:ok, socket}
  end

  def handle_event("mark_as_read", %{"entry-id" => entry_id}, socket) do
    changeset =
      Repo.get!(User, socket.assigns.current_user.id)
      |> Ecto.assoc(:entries)
      |> Repo.get!(entry_id)
      |> Entry.changeset(%{"read" => true})

    case Repo.update(changeset) do
      {:ok, entry} ->
        feed_with_counts_query =
          from(
            f in Feed,
            join: e in Entry,
            on: f.id == e.feed_id,
            group_by: f.id,
            select: %{
              f
              | unread_entries_count: filter(count(e.id), e.read == false),
                read_entries_count: filter(count(e.id), e.read == true),
                has_error: f.retries > 0
            }
          )

        updated_feed =
          Repo.get!(feed_with_counts_query, entry.feed_id)
          |> Repo.preload(
            entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
          )

        update_broadcaster =
          Application.get_env(:ex_rss, :update_broadcaster, ExRss.Crawler.UpdateBroadcaster)

        Task.Supervisor.start_child(
          ExRss.TaskSupervisor,
          update_broadcaster,
          :broadcast_update,
          [updated_feed]
        )

        oldest_unread_entry =
          User.oldest_unread_entry(socket.assigns.current_user.id)

        socket =
          socket
          |> assign(:oldest_unread_entry, oldest_unread_entry)
          |> stream_insert(:feeds, updated_feed)

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("mark_as_read", %{"feed-id" => feed_id}, socket) do
    changeset =
      Repo.get!(User, socket.assigns.current_user.id)
      |> Ecto.assoc(:feeds)
      |> Repo.get!(feed_id)
      |> Repo.preload(:entries)
      |> Feed.mark_as_read()

    case Repo.update(changeset) do
      {:ok, feed} ->
        feed_with_counts_query =
          from(
            f in Feed,
            join: e in Entry,
            on: f.id == e.feed_id,
            group_by: f.id,
            select: %{
              f
              | unread_entries_count: filter(count(e.id), e.read == false),
                read_entries_count: filter(count(e.id), e.read == true),
                has_error: f.retries > 0
            }
          )

        updated_feed =
          Repo.get!(feed_with_counts_query, feed.id)
          |> Repo.preload(
            entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
          )

        update_broadcaster =
          Application.get_env(:ex_rss, :update_broadcaster, ExRss.Crawler.UpdateBroadcaster)

        Task.Supervisor.start_child(
          ExRss.TaskSupervisor,
          update_broadcaster,
          :broadcast_update,
          [updated_feed]
        )

        oldest_unread_entry =
          User.oldest_unread_entry(socket.assigns.current_user.id)

        socket =
          socket
          |> assign(:oldest_unread_entry, oldest_unread_entry)
          |> stream_insert(:feeds, updated_feed)

        {:noreply, socket}

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

  def update_feed_position(feed_id, position, socket) do
    changeset =
      Repo.get!(User, socket.assigns.current_user.id)
      |> Ecto.assoc(:feeds)
      |> Repo.get!(feed_id)
      |> Feed.changeset(%{"position" => position})

    case Repo.update(changeset) do
      {:ok, feed} ->
        current_user = Repo.get!(User, socket.assigns.current_user.id)

        feeds_of_current_user = current_user |> Ecto.assoc(:feeds)

        feeds_with_counts =
          from(
            f in feeds_of_current_user,
            join: e in Entry,
            on: f.id == e.feed_id,
            group_by: f.id,
            order_by: [desc_nulls_last: f.position],
            select: %{
              f
              | unread_entries_count: filter(count(e.id), e.read == false),
                read_entries_count: filter(count(e.id), e.read == true),
                has_error: f.retries > 0
            }
          )

        feeds =
          feeds_with_counts
          |> Repo.all()
          |> Repo.preload(
            entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
          )

        feed_with_counts_query =
          from(
            f in Feed,
            join: e in Entry,
            on: f.id == e.feed_id,
            group_by: f.id,
            select: %{
              f
              | unread_entries_count: filter(count(e.id), e.read == false),
                read_entries_count: filter(count(e.id), e.read == true),
                has_error: f.retries > 0
            }
          )

        updated_feed =
          Repo.get!(feed_with_counts_query, feed.id)
          |> Repo.preload(
            entries: from(e in Entry, where: e.read == false, order_by: [desc: e.posted_at])
          )

        update_broadcaster =
          Application.get_env(:ex_rss, :update_broadcaster, ExRss.Crawler.UpdateBroadcaster)

        Task.Supervisor.start_child(
          ExRss.TaskSupervisor,
          update_broadcaster,
          :broadcast_update,
          [updated_feed]
        )

        oldest_unread_entry =
          User.oldest_unread_entry(socket.assigns.current_user.id)

        socket =
          socket
          |> assign(:oldest_unread_entry, oldest_unread_entry)
          |> stream(:feeds, feeds, reset: true)

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  # 2024-12-03
  # This `use` is needed for `content_tag` to be available in `elm_module`.
  use Phoenix.HTML

  def elm_module(module, params \\ %{}, attrs \\ []) do
    {tag, attrs} = Keyword.pop(attrs, :tag, :div)

    data_attributes = [
      "data-elm-module": module,
      "data-elm-params": html_escape(Jason.encode!(params)),
      "phx-hook": "ElmModules"
    ]

    content_tag(tag, "", Keyword.merge(attrs, data_attributes))
  end

  attr :entry, Entry, required: true

  def entry(assigns) do
    ~H"""
    <ul class="flex flex-col">
      <li class="flex flex-col md:flex-row">
        <div class="flex flex-col">
          <a href={@entry.url} target="_blank"><%= @entry.title %></a>
          <span><%= @entry.posted_at %></span>
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
        <div><%= @number_of_entries_not_shown %> entries not shown</div>
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
end
