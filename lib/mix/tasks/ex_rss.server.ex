defmodule Mix.Tasks.ExRss.Server do
  use Mix.Task

  @shortdoc "Starts an ExRss server"

  def run(args) do
    Application.put_env(:ex_rss, :start_crawler, true, persistent: true)

    Mix.Task.run("phx.server", args)
  end
end
