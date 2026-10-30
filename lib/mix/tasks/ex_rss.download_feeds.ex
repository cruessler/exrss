defmodule Mix.Tasks.ExRss.DownloadFeeds do
  use Mix.Task

  alias ExRss.{FeedDownloader, FeedImporter}

  @shortdoc "Download all feeds in an OPML file"

  @moduledoc """
  Download all feeds in an OPML file into the specified directory.

      mix ex_rss.download_feeds feeds.opml directory

  The directory must already exist; if it doesn't, the task will raise an
  exception.
  """

  def run(args) do
    case args do
      [filename, directory] ->
        Mix.Task.run("app.start")

        opml = File.read!(filename)
        feeds = FeedImporter.extract_feeds(opml)

        Mix.shell().info("Downloading #{length(feeds)} feeds to #{directory} …")

        FeedDownloader.download_feeds(feeds, directory)

        Mix.shell().info("Done")

      _ ->
        Mix.raise("Usage: mix ex_rss.download_feeds <FILENAME> <DIRECTORY>")
    end
  end
end
