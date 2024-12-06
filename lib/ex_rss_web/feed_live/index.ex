defmodule ExRssWeb.FeedLive.Index do
  use ExRssWeb, :live_view

  alias ExRss.User

  def mount(
        _params,
        %{"api_token" => api_token, "current_user" => current_user} = _session,
        socket
      ) do
    oldest_unread_entry = User.oldest_unread_entry(current_user.id)

    socket =
      socket
      |> assign(:api_token, api_token)
      |> assign(:oldest_unread_entry, oldest_unread_entry)

    {:ok, socket}
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
