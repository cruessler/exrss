defmodule Mix.Tasks.ExRss.Data do
  use Mix.Task

  alias ExRss.{Entry, Feed, Repo}

  @shortdoc "Deletes feeds and entries"

  @moduledoc """
  Deletes feeds and entries. This is useful for development.

      mix ex_rss.data --delete

  """

  @switches [
    delete: :boolean
  ]

  def run(args) do
    {opts, _} = OptionParser.parse_head!(args, strict: @switches)

    cond do
      opts[:delete] ->
        delete()

      true ->
        Mix.Task.run("help", ["ex_rss.data"])
    end
  end

  def delete do
    Mix.Task.run("app.start")

    Mix.shell().info("Deleting feeds and entries …")

    {entries_deleted, _} = Entry |> Repo.delete_all()
    {feeds_deleted, _} = Feed |> Repo.delete_all()

    Mix.shell().info("Deleted #{entries_deleted} entries and #{feeds_deleted} feeds")
  end
end
