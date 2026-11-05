defmodule ExRss.FeedParser do
  def parse(xml) do
    result =
      :xmerl_sax_parser.stream(xml,
        event_fun: &handle_event/3,
        event_state: %{
          current_entries: [],
          element_stack: [],
          current_text_parts: [],
          current_entry: nil,
          feed: nil
        }
      )

    case result do
      {:ok, %{element_stack: [], feed: %{} = feed}, _remaining_input} ->
        {:ok, feed}

      {:ok, %{feed: nil}, _remaining_input} ->
        {:error, :no_feed_found}

      {:fatal_error, _location, reason, _end_tags, _state} ->
        {:error, {:xml_parsing_failed, reason}}
    end
  end

  @atom_uri ~c"http://www.w3.org/2005/Atom"

  @default_entry %{title: nil, link: nil, updated: nil}
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
         {:startElement, @atom_uri, ~c"link", _qualified_name, attributes},
         _location,
         %{element_stack: [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    href =
      Enum.find_value(attributes, fn
        {[], _prefix, ~c"href", href} ->
          List.to_string(href)

        _ ->
          nil
      end)

    rel =
      Enum.find_value(attributes, fn
        {[], _prefix, ~c"rel", rel} ->
          List.to_string(rel)

        _ ->
          nil
      end)

    state = %{state | element_stack: [{@atom_uri, ~c"link"} | state.element_stack]}

    # This is designed to match `FeederEx`'s behaviour.
    if href not in [nil, ""] and rel != "shorturl" and state.current_entry.link == nil do
      %{state | current_entry: %{state.current_entry | link: href}}
    else
      state
    end
  end

  defp handle_event(
         {:startElement, [], ~c"rss", _qualified_name, attributes},
         _location,
         %{element_stack: []} = state
       ) do
    version =
      Enum.find_value(attributes, fn
        {[], _prefix, ~c"version", version} ->
          List.to_string(version)

        _ ->
          nil
      end)

    feed =
      if version == "2.0" do
        @default_feed
      else
        nil
      end

    %{
      state
      | element_stack: [{[], ~c"rss"} | state.element_stack],
        feed: feed
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

  @text_paths [
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}],
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}],
    [{@atom_uri, ~c"updated"}, {@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]
  ]

  defp handle_event(
         {event, text},
         _location,
         %{element_stack: element_stack} = state
       )
       when event in [:characters, :ignorableWhitespace] and element_stack in @text_paths do
    %{state | current_text_parts: [text | state.current_text_parts]}
  end

  @title_paths [
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"feed"}],
    [{@atom_uri, ~c"title"}, {@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]
  ]

  defp handle_event(
         {:endElement, @atom_uri, ~c"title", _qualified_name},
         _location,
         %{element_stack: element_stack} = state
       )
       when element_stack in @title_paths do
    [_ | rest] = element_stack
    title = state.current_text_parts |> Enum.reverse() |> Enum.join()

    case rest do
      [{@atom_uri, ~c"feed"}] ->
        %{
          state
          | element_stack: rest,
            current_text_parts: [],
            feed: %{state.feed | title: title}
        }

      [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}] ->
        %{
          state
          | element_stack: rest,
            current_text_parts: [],
            current_entry: %{state.current_entry | title: title}
        }
    end
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"updated", _qualified_name},
         _location,
         %{
           element_stack: [
             {@atom_uri, ~c"updated"},
             {@atom_uri, ~c"entry"},
             {@atom_uri, ~c"feed"}
           ]
         } = state
       ) do
    updated = state.current_text_parts |> Enum.reverse() |> Enum.join()

    %{
      state
      | element_stack: [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}],
        current_text_parts: [],
        current_entry: %{state.current_entry | updated: updated}
    }
  end

  defp handle_event(
         {:endElement, @atom_uri, ~c"entry", _qualified_name},
         _location,
         %{element_stack: [{@atom_uri, ~c"entry"}, {@atom_uri, ~c"feed"}]} = state
       ) do
    %{
      state
      | element_stack: [{@atom_uri, ~c"feed"}],
        current_entry: nil,
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
         {:endElement, [], ~c"rss", _qualified_name},
         _location,
         %{element_stack: [{[], ~c"rss"}], feed: feed} = state
       ) do
    feed =
      if feed == nil do
        nil
      else
        %{feed | entries: state.current_entries |> Enum.reverse()}
      end

    %{
      state
      | element_stack: [],
        current_entries: [],
        feed: feed
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
