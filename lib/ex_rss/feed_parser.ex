defmodule ExRss.FeedParser do
  def parse(xml) do
    :xmerl_sax_parser.stream(xml,
      event_fun: &handle_event/3,
      event_state: %{
        item_count: 0,
        element_stack: [],
        current_title_parts: [],
        current_title: nil,
        feed: nil
      }
    )
  end

  @atom_uri ~c"http://www.w3.org/2005/Atom"

  defp handle_event(
         {:startElement, @atom_uri, ~c"feed", _qualified_name, _attributes},
         _location,
         %{element_stack: []} = state
       ) do
    %{state | element_stack: [{@atom_uri, ~c"feed"} | state.element_stack]}
  end

  defp handle_event(
         {:startElement, @atom_uri, ~c"entry", _qualified_name, _attributes},
         _location,
         %{element_stack: [{@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | item_count: state.item_count + 1,
        element_stack: [{@atom_uri, ~c"entry"} | state.element_stack]
    }
  end

  defp handle_event(
         {:startElement, uri, name, _qualified_name, _attributes},
         _location,
         state
       ) do
    %{
      state
      | element_stack: [{uri, name} | state.element_stack]
    }
  end

  defp handle_event(
         {:characters, text},
         _location,
         %{element_stack: [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    %{state | current_title_parts: [text | state.current_title_parts]}
  end

  defp handle_event(
         {:ignorableWhitespace, text},
         _location,
         %{element_stack: [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    %{state | current_title_parts: [text | state.current_title_parts]}
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"title", _qualified_name},
         _location,
         %{element_stack: [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | element_stack: [{@atom_uri, ~c"feed"}],
        current_title_parts: [],
        current_title: state.current_title_parts |> Enum.reverse() |> Enum.join()
    }
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"feed", _qualified_name},
         _location,
         %{element_stack: [{@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | element_stack: [],
        current_title: nil,
        feed: %{title: state.current_title}
    }
  end

  defp handle_event(
         {:endElement, uri, name, _qualified_name},
         _location,
         %{element_stack: [{uri, name} | rest]} = state
       ) do
    %{state | element_stack: rest}
  end

  defp handle_event(_event, _location, state), do: state
end
