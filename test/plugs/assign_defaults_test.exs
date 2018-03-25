defmodule ExRss.AssignDefaultsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExRss.Plug.AssignDefaults

  @plug AssignDefaults.init([])

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  test "Plug.AssignDefaults" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(@session)
      |> AssignDefaults.call(@plug)

    assert is_nil(conn.assigns.current_user)
  end
end
