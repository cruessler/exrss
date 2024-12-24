defmodule ExRssWeb.AppView do
  use PhoenixHTMLHelpers

  def form_group(form, field, attrs, fun) when is_function(fun, 1) do
    {class, _attrs} = Keyword.pop(attrs, :class, "")

    if Keyword.has_key?(form.errors, field) do
      # TODO
      # Append class indicating error.
    end

    content_tag(:div, fun.(form), class: class)
  end
end
