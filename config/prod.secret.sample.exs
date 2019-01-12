use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :ex_rss, ExRss.Endpoint, secret_key_base: ""

# Configure your database
config :ex_rss, ExRss.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "",
  password: "",
  database: "",
  pool_size: 20
