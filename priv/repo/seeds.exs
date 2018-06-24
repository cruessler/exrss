# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExRss.Repo.insert!(%ExRss.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ExRss.Entry
alias ExRss.Feed
alias ExRss.Repo
alias ExRss.User

Repo.insert!(%User{email: "jane@doe.com"})
Repo.insert!(%Feed{user_id: 1, title: "Title", url: "http://example.com"})

Repo.insert!(%Entry{
  url: "http://example.com",
  title: "Title",
  raw_posted_at: "Sun, 21 Dec 2014 16:08:00 +0100",
  read: false,
  feed_id: 1
})
