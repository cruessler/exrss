defmodule ExRss.User.Account do
  use ExRssWeb, :model

  schema "users" do
    field :email, :string
  end
end
