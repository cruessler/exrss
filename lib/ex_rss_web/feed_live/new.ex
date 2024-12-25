defmodule ExRssWeb.FeedLive.New do
  use ExRssWeb, :live_view

  alias ExRss.{Repo, User}
  alias ExRss.FeedAdder

  def mount(%{"url" => url}, _session, socket) do
    current_user = socket.assigns.current_user

    candidate =
      case FeedAdder.discover_feed(url) do
        {:ok, candidate} -> candidate
        _ -> nil
      end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:candidate, candidate)
      |> assign(:added_feed, nil)

    {:ok, socket}
  end

  def mount(
        _params,
        _session,
        socket
      ) do
    socket =
      socket
      |> assign(:candidate, nil)
      |> assign(:added_feed, nil)

    {:ok, socket}
  end

  def handle_event("add_feed", feed_params, socket) do
    multi =
      Repo.get!(User, socket.assigns.current_user.id)
      |> FeedAdder.add_feed(feed_params)

    case Repo.transaction(multi) do
      {:ok, %{feed: added_feed}} ->
        socket =
          socket
          |> assign(:candidate, nil)
          |> assign(:added_feed, added_feed)

        {:noreply, socket}

      {:error, _error} ->
        {:noreply, socket}
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
