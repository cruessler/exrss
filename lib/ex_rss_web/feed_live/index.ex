defmodule ExRssWeb.FeedLive.Index do
  use ExRssWeb, :live_view

  def mount(_params, %{"api_token" => api_token} = _session, socket) do
    {:ok, assign(socket, :api_token, api_token)}
  end

  # 2024-12-03
  # This `use` is needed for `content_tag` to be available in `elm_module`.
  use Phoenix.HTML

  def elm_module(module, params \\ %{}, attrs \\ []) do
    {tag, attrs} = Keyword.pop(attrs, :tag, :div)

    data_attributes = [
      "data-elm-module": module,
      "data-elm-params": html_escape(Jason.encode!(params))
    ]

    content_tag(tag, "", Keyword.merge(attrs, data_attributes))
  end
end
