defmodule ExRss.User do
  use ExRss.Web, :model

  alias ExRss.Feed

  schema "users" do
    field :email, :string
    field :hashed_password, :string

    has_many :feeds, Feed
    has_many :entries, through: [:feeds, :entries]

    timestamps()
  end
end
