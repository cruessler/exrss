defmodule ExRss.AuthenticationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExRss.Plug.Authentication
  alias ExRss.User

  @plug Authentication.init("/")

  test "Plug.Authentication" do
    conn =
      conn(:get, "/")
      |> Authentication.call(@plug)

    assert conn.status == 302

    conn =
      conn(:get, "/")
      |> assign(:current_user, %User{})
      |> Authentication.call(@plug)

    assert conn.status != 302
  end
end
