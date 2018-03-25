defmodule ExRss do
  use Application

  import Supervisor.Spec

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(ExRss.Repo, []),
        # Start the endpoint when the application starts
        supervisor(ExRss.Endpoint, [])
        # Start your own worker by calling: ExRss.Worker.start_link(arg1, arg2, arg3)
        # worker(ExRss.Worker, [arg1, arg2, arg3]),
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

  defp workers(true), do: [worker(ExRss.Crawler.Queue, [])]
  defp workers(_), do: []
end
