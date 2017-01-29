defmodule ExRss.User.RegistrationTest do
  use ExRss.ModelCase

  alias ExRss.User.Registration

  @password "password"
  @email "jane@doe.com"

  test "register User" do
    changeset = Registration.changeset(%Registration{}, %{password: ""})
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, %{password: @password})
    refute changeset.valid?

    params = %{password: @password, password_confirmation: @password}
    changeset = Registration.changeset(%Registration{}, params)
    refute changeset.valid?

    params = %{email: @email, password: @password, password_confirmation: @password}
    changeset = Registration.changeset(%Registration{}, params)
    assert changeset.valid?
  end
end
