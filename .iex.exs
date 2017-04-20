alias ExRss.Repo
alias ExRss.User

alias ExRss.{Feed, Entry}

defmodule Debug do
  def sql_query(sql), do: Ecto.Adapters.SQL.query(Repo, sql)
end
