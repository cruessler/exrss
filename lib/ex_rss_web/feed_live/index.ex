defmodule ExRssWeb.FeedLive.Index do
  use ExRssWeb, :live_view

  alias ExRss.{Entry, Feed, Repo, User}

  def mount(
        _params,
        %{"api_token" => api_token, "current_user" => current_user} = _session,
        socket
      ) do
    oldest_unread_entry = User.oldest_unread_entry(current_user.id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:api_token, api_token)
      |> assign(:oldest_unread_entry, oldest_unread_entry)

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
        updated_feed = Repo.get!(Feed, entry.feed_id)

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

        {:noreply, assign(socket, :oldest_unread_entry, oldest_unread_entry)}

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
end
