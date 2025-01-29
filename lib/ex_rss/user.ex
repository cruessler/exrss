defmodule ExRss.User do
  use ExRssWeb, :model

  alias Ecto.Changeset

  alias ExRss.Feed
  alias ExRss.Repo
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

  def newest_unread_entry(user_id) do
    user = Repo.get!(User, user_id)

    from(e in assoc(user, :entries),
      where: e.read == false,
      order_by: [desc: :posted_at],
      limit: 1
    )
    |> Repo.all()
    |> List.first()
  end

  def oldest_unread_entry(user_id) do
    user = Repo.get!(User, user_id)

    from(e in assoc(user, :entries),
      where: e.read == false,
      order_by: [asc: :posted_at],
      limit: 1
    )
    |> Repo.all()
    |> List.first()
  end
end
