defmodule ExRss.FeedParser do
  def parse(xml) do
    :xmerl_sax_parser.stream(xml,
      event_fun: &handle_event/3,
      event_state: %{
        current_entries: [],
        element_stack: [],
        current_title_parts: [],
        current_entry: nil,
        feed: nil
      }
    )
  end

  @atom_uri ~c"http://www.w3.org/2005/Atom"

  @default_entry %{title: nil}
  @default_feed %{title: nil, entries: []}

  defp handle_event(
         {:startElement, @atom_uri, ~c"feed", _qualified_name, _attributes},
         _location,
         %{element_stack: []} = state
       ) do
    %{
      state
      | element_stack: [{@atom_uri, ~c"feed"} | state.element_stack],
        feed: @default_feed
    }
  end

  defp handle_event(
         {:startElement, @atom_uri, ~c"entry", _qualified_name, _attributes},
         _location,
         %{element_stack: [{@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | element_stack: [{@atom_uri, ~c"entry"} | state.element_stack],
        current_entry: @default_entry
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

  @title_paths [
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}],
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]
  ]

  defp handle_event(
         {event, text},
         _location,
         %{element_stack: element_stack} = state
       )
       when event in [:characters, :ignorableWhitespace] and element_stack in @title_paths do
    %{state | current_title_parts: [text | state.current_title_parts]}
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"title", _qualified_name},
         _location,
         %{element_stack: element_stack} = state
       )
       when element_stack in @title_paths do
    [_ | rest] = element_stack
    title = state.current_title_parts |> Enum.reverse() |> Enum.join()

    case rest do
      [{@atom_uri, ~c"feed"}] ->
        %{
          state
          | element_stack: rest,
            current_title_parts: [],
            feed: %{state.feed | title: title}
        }

      [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}] ->
        %{
          state
          | element_stack: rest,
            current_title_parts: [],
            current_entry: %{state.current_entry | title: title}
        }

      _ ->
        %{state | element_stack: rest, current_title_parts: []}
    end
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"entry", _qualified_name},
         _location,
         %{element_stack: [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | element_stack: [{@atom_uri, ~c"feed"}],
        current_entry: @default_entry,
        current_entries: [state.current_entry | state.current_entries]
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
        current_entries: [],
        feed: %{state.feed | entries: state.current_entries |> Enum.reverse()}
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
