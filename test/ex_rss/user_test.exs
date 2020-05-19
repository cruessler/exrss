defmodule ExRss.UserTest do
  use ExRss.DataCase

  alias Ecto.Changeset
  alias ExRss.User

  @user %User{id: 1}

  test "gets and validates remember_me_token" do
    changeset = User.renew_remember_me_token(@user)
    remember_me_token = Changeset.get_change(changeset, :remember_me_token)

    assert is_binary(remember_me_token)

    assert {:ok, @user} = User.verify_remember_me_token(remember_me_token)
  end
end
