defmodule ExRss do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        ExRss.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: ExRss.PubSub},
        # Start the endpoint when the application starts
        ExRss.Endpoint
        # Start your own worker by calling: ExRss.Worker.start_link(arg)
        # {ExRss.Worker, arg},
      ] ++ workers(Application.get_env(:ex_rss, :start_crawler))

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExRss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExRss.Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(true), do: [ExRss.Crawler.Queue]
  defp workers(_), do: []
end
