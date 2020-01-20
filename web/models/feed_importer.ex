defmodule ExRss.FeedImporter do
  alias ExRss.Repo

  alias ExRss.Feed

  def import_file(filename) do
    with {:ok, string} <- File.read(filename),
         {:ok, html} <- Floki.parse_document(string),
         feeds = extract_feeds(html) do
      {feeds_imported, _} = Repo.insert_all(Feed, feeds)

      {:ok, feeds_imported}
    end
  end

  def extract_feeds(string) do
    now = DateTime.utc_now()

    with {:ok, html} <- Floki.parse_document(string) do
      html
      |> Floki.find("outline[type=rss]")
      |> Enum.map(fn feed ->
        with [title] <- Floki.attribute(feed, "text"),
             [url] <- Floki.attribute(feed, "xmlurl") do
          %{title: title, url: url, inserted_at: now, updated_at: now}
        else
          [] -> nil
        end
      end)
      |> Enum.reject(&is_nil(&1))
    else
      []
    end
  end
end
