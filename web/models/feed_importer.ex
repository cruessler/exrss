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
    |> Floki.find("outline[type=rss]")
    |> Enum.map(fn feed ->
      with [title] <- Floki.attribute(feed, "text"),
           [url] <- Floki.attribute(feed, "xmlurl")
      do
        %{title: title, url: url, inserted_at: now, updated_at: now}
      else
        [] -> nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))
  end
end
