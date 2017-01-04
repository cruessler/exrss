defmodule Mix.Tasks.ExRss.ImportFeeds do
  use Mix.Task

  alias ExRss.FeedImporter

  @shortdoc "Imports an OPML file containing feeds"

  def run(args) do
    case args do
      [filename] ->
        Mix.Task.run "app.start"

        Mix.shell.info "Importing file #{filename} …"

        case FeedImporter.import_file(filename) do
          {:ok, feeds_imported} ->
            Mix.shell.info "Imported #{feeds_imported} feeds"

          {:error, message} ->
            Mix.shell.error message
        end
    end
  end
end
