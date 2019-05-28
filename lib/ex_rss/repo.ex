defmodule ExRss.Repo do
  use Ecto.Repo, otp_app: :ex_rss, adapter: Ecto.Adapters.Postgres
end
