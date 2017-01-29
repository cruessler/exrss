defmodule ExRss.User do
  use ExRss.Web, :model

  alias ExRss.Feed

  schema "users" do
    field :email, :string

    has_many :feeds, Feed

    timestamps()
  end
end
