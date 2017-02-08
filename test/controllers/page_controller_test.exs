defmodule ExRss.PageControllerTest do
  use ExRss.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to ExRss!"
  end
end
