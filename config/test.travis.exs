use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_rss, ExRssWeb.Endpoint,
  http: [port: 4001],
  server: false,
  secret_key_base: String.duplicate("a", 64)

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :ex_rss, ExRss.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "travis_ci_test",
  pool: Ecto.Adapters.SQL.Sandbox
