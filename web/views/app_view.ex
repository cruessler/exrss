defmodule ExRss.AppView do
  use Phoenix.HTML

  def form_group(form, field, fun) when is_function(fun, 1) do
    class =
      if Keyword.has_key?(form.errors, field) do
        "form-group row has-warning"
      else
        "form-group row"
      end

    content_tag :div, fun.(form), class: class
  end
end
