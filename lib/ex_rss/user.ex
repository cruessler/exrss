defmodule ExRss.User do
  use ExRssWeb, :model

  alias Ecto.Changeset

  alias ExRss.Feed
  alias ExRss.User

  @timestamps_opts [type: :utc_datetime]

  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :remember_me_token, :string

    has_many :feeds, Feed
    has_many :entries, through: [:feeds, :entries]

    timestamps()
  end

  @context ExRssWeb.Endpoint
  @salt "remember_me"
  # 3 days
  @max_age 86_400 * 3

  def renew_remember_me_token(user) do
    token = Phoenix.Token.sign(@context, @salt, %User{id: user.id})

    Changeset.change(user, remember_me_token: token)
  end

  def verify_remember_me_token(token) do
    Phoenix.Token.verify(@context, @salt, token, max_age: @max_age)
  end
end
