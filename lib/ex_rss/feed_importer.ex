defmodule ExRss.FeedImporter do
  alias ExRss.Repo

  alias ExRss.Feed

  def import_file(filename) do
    with {:ok, string} <- File.read(filename) do
      feeds = extract_feeds(string)

      {feeds_imported, _} = Repo.insert_all(Feed, feeds)

      {:ok, feeds_imported}
    else
      x ->
        x
    end
  end

  def extract_feeds(string) do
    now = DateTime.utc_now()

    string
    |> LazyHTML.from_document()
    |> LazyHTML.query("outline[type=rss]")
    |> Enum.map(fn feed ->
      with [title] <- LazyHTML.attribute(feed, "text"),
           [url] <- LazyHTML.attribute(feed, "xmlurl") do
        %{title: title, url: url, inserted_at: now, updated_at: now}
      else
        [] -> nil
      end
    end)
    |> Enum.reject(&is_nil(&1))
  end
end
