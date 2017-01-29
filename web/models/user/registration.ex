defmodule ExRss.User.Registration do
  use ExRss.Web, :model

  alias Comeonin.Bcrypt

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :hashed_password, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8)
    |> validate_length(:password_confirmation, min: 8)
    |> validate_confirmation(:password)
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> encrypt_password
  end

  def encrypt_password(%{changes: %{password: password}} = changeset) do
    hashed_password = Bcrypt.hashpwsalt(password)

    changeset
    |> delete_change(:password)
    |> put_change(:hashed_password, hashed_password)
  end
  def encrypt_password(changeset) do
    changeset
  end
end
