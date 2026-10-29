defmodule Mix.Tasks.ExRss.ExportFeeds do
  use Mix.Task

  alias ExRss.{FeedExporter, Repo, User}

  @shortdoc "Exports a user's feeds to an OPML file"

  def run(args) do
    case args do
      [user_id, filename] ->
        user_id =
          case Integer.parse(user_id) do
            {user_id, ""} -> user_id
            _ -> Mix.raise("#{user_id} could not be parsed as a user id")
          end

        Mix.Task.run("app.start")

        user = Repo.get!(User, user_id) |> Repo.preload(:feeds)

        Mix.shell().info("Exporting user ##{user_id}'s feeds to #{filename} …")

        case FeedExporter.export_feeds(user.feeds) do
          {:ok, xml} ->
            File.write!(filename, xml)

            Mix.shell().info("Exported #{length(user.feeds)} feeds")

          {:error, :no_feeds_to_export} ->
            Mix.raise("User ##{user_id} has no feeds to export")
        end

      _ ->
        Mix.raise("Usage: mix ex_rss.export_feeds <USER_ID> <FILENAME>")
    end
  end
end
