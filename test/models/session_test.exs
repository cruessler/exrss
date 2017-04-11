defmodule ExRss.SessionTest do
  use ExRss.ModelCase

  alias ExRss.Session
  alias ExRss.User.Registration

  @password "password"
  @email "john@doe.com"

  test "login" do
    params = %{email: @email, password: @password, password_confirmation: @password}
    {:ok, _} = Registration.changeset(%Registration{}, params) |> Repo.insert

    assert {:ok, _} = Session.login(%{"email"=> @email, "password"=> @password})
    assert :error = Session.login(%{"email" => "", "password" => ""})
  end
end
