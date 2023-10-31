defmodule ExRssWeb.AppView do
  use Phoenix.HTML

  def form_group(form, field, attrs, fun) when is_function(fun, 1) do
    {class, _attrs} = Keyword.pop(attrs, :class, "")

    if Keyword.has_key?(form.errors, field) do
      # TODO
      # Append class indicating error.
    end

    content_tag(:div, fun.(form), class: class)
  end

  def elm_module(module, params \\ %{}, attrs \\ []) do
    {tag, attrs} = Keyword.pop(attrs, :tag, :div)

    data_attributes = [
      "data-elm-module": module,
      "data-elm-params": html_escape(Jason.encode!(params))
    ]

    content_tag(tag, "", Keyword.merge(attrs, data_attributes))
  end
end
