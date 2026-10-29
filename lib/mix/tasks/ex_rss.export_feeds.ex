defmodule Mix.Tasks.ExRss.ExportFeeds do
  use Mix.Task

  alias ExRss.{FeedExporter, Repo, User}

  @shortdoc "Exports a user's feeds to an OPML file"

  def run(args) do
    case args do
      [user_id, filename] ->
        Mix.Task.run("app.start")

        user = Repo.get!(User, user_id) |> Repo.preload(:feeds)

        Mix.shell().info("Exporting user ##{user_id}'s feeds to #{filename} …")

        case FeedExporter.export_feeds(user.feeds) do
          {:ok, xml} ->
            File.write!(filename, xml)

            Mix.shell().info("Exported #{length(user.feeds)} feeds")

          {:error, message} ->
            Mix.shell().error(message)
        end
    end
  end
end
