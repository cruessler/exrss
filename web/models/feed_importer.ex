defmodule ExRss.FeedImporter do
  alias ExRss.Repo

  alias ExRss.Feed

  def import_file(filename) do
    with {:ok, string} <- File.read(filename),
         html <- Floki.parse(string),
         feeds = extract_feeds(html)
    do
      {feeds_imported, _} = Repo.insert_all(Feed, feeds)

      {:ok, feeds_imported}
    end
  end

  def extract_feeds(html) do
    now = DateTime.utc_now

    html
    |> Floki.find("outline")
    |> Enum.map(fn feed ->
      case feed do
        {"outline",
          [{"type", "rss"},
           {"text", title},
           {"xmlurl", url}|_],
          []} ->
          %{title: title, url: url, inserted_at: now, updated_at: now}

        _ -> nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))
  end
end
