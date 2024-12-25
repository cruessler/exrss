import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_rss, ExRssWeb.Endpoint,
  http: [port: 4001],
  server: false,
  secret_key_base: String.duplicate("a", 64)

# In test we don't send emails.
config :lightweight_todo, ExRss.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Configure your database
config :ex_rss, ExRss.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "ex_rss",
  password: "ex_rss",
  database: "ex_rss_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
