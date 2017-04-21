alias ExRss.Repo
alias ExRss.User

alias ExRss.{Feed, Entry}

defmodule Debug do
  def sql_query(sql), do: Ecto.Adapters.SQL.query(Repo, sql)

  def delete_feeds! do
    Repo.delete_all(Entry)
    Repo.delete_all(Feed)
  end
end
