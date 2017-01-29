defmodule ExRss.User.Account do
  use ExRss.Web, :model

  schema "users" do
    field :email, :string
    field :hashed_password, :string
  end
end
