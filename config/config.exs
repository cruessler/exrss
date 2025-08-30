# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :ex_rss,
  ecto_repos: [ExRss.Repo]

# Configures the endpoint
config :ex_rss, ExRssWeb.Endpoint,
  url: [host: "localhost"],
  # TODO
  # `secret_key_base` seems to have been removed by Phoenix 1.7 or an earlier
  # version.
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [signing_salt: "abcdefgh"],
  render_errors: [
    formats: [html: ExRssWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: ExRss.PubSub

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails locally. You
# can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter at the
# `config/runtime.exs`.
config :ex_rss, ExRss.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  ex_rss: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :title, :url, :error]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
