defmodule ExRss.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ExRss.Repo,
        {Phoenix.PubSub, name: ExRss.PubSub},
        ExRssWeb.Endpoint
      ] ++ workers(Application.get_env(:ex_rss, :start_crawler))

    opts = [strategy: :one_for_one, name: ExRss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ExRssWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(true), do: [ExRss.Crawler.Queue]
  defp workers(_), do: []
end
