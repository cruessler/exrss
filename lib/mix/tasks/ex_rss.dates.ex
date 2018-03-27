defmodule Mix.Tasks.ExRss.Dates do
  use Mix.Task

  alias ExRss.DateParser

  @shortdoc "Checks and parses publication dates"

  @moduledoc """
  Lists publication dates that could not be parsed, clears all parsed dates, or
  tries to parse dates that are not yet parsed.

      mix ex_rss.dates --list-unparsed --number 10
      mix ex_rss.dates --clear-parsed
      mix ex_rss.dates --parse

  ## Options

    * `-n, --number` - specifies how many entries to show when listing unparsed
    dates.

  """

  @default_number 10

  @switches [
    list_unparsed: :boolean,
    clear_parsed: :boolean,
    parse: :boolean,
    number: :integer
  ]

  @aliases [n: :number]

  def run(args) do
    {opts, _} = OptionParser.parse_head!(args, strict: @switches, aliases: @aliases)

    cond do
      opts[:list_unparsed] ->
        list_unparsed(opts[:number] || @default_number)

      opts[:clear_parsed] ->
        clear_parsed()

      opts[:parse] ->
        parse()
    end
  end

  def list_unparsed(number) do
    Mix.Task.run("app.start")

    Mix.shell().info("Listing unparsed dates (up to #{number}) …")

    DateParser.list_unparsed(number)
    |> Enum.map(fn entry -> Mix.shell().info("[#{entry.id}] #{entry.raw_posted_at}") end)

    Mix.shell().info("Use `mix ex_rss.dates --parse` to try and parse unparsed dates")
  end

  def clear_parsed() do
    Mix.Task.run("app.start")

    Mix.shell().info("Clearing parsed dates …")

    {n, _} = DateParser.clear_parsed()

    Mix.shell().info("#{n} dates cleared")
  end

  def parse do
    Mix.Task.run("app.start")

    Mix.shell().info("Attempting to parse unparsed dates …")

    {successes, errors} = DateParser.parse()

    Mix.shell().info(
      "Dates parsed\t\t#{successes}\n" <>
        "Dates failed to parse\t#{errors}\n" <>
        "Use `mix ex_rss.dates --list-unparsed` to list dates that could not be parsed"
    )
  end
end
