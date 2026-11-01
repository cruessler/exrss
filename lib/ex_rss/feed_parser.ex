defmodule ExRss.FeedParser do
  def parse(xml) do
    :xmerl_sax_parser.stream(xml, event_fun: &handle_event/3, event_state: %{item_count: 0})
  end

  defp handle_event(
         {:startElement, ~c"http://www.w3.org/2005/Atom", ~c"entry", _qualified_name,
          _attributes},
         _location,
         state
       ) do
    %{state | item_count: state.item_count + 1}
  end

  defp handle_event(_event, _location, state), do: state
end
