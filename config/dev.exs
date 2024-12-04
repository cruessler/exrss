import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to recompile .js and .css sources.
config :ex_rss, ExRssWeb.Endpoint,
  http: [port: 4000, protocol_options: [max_header_value_length: 8192]],
  # TODO
  # `secret_key_base` seems to have been removed by Phoenix 1.7 or an earlier
  # version.
  secret_key_base: String.duplicate("abcdefgh", 8),
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: ["build.mjs", "--watch", cd: Path.expand("../assets", __DIR__)],
    npx: [
      "tailwindcss",
      "-i",
      "./css/app.css",
      "-o",
      "../priv/static/assets/app.css",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :ex_rss, ExRssWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/ex_rss_web/views/.*(ex)$},
      ~r{lib/ex_rss_web/templates/.*(eex)$}
    ]
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Configure your database
config :ex_rss, ExRss.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "ex_rss",
  password: "ex_rss",
  database: "ex_rss_dev",
  hostname: "localhost",
  pool_size: 10
