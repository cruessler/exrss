defmodule ExRss.Api.V1.FeedControllerTest do
  use ExRss.ConnCase

  test "POST /feeds return new feed on success", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> post("/api/v1/feeds",
        [feed: [title: "Title", url: "http://www.example.com"]])

    response = json_response(conn, 200)
    assert %{"id" => _, "title" => "Title"} = response
  end

  test "POST /feeds return errors on failure", %{conn: conn} do
    conn =
      conn
      |> with_authorization
      |> post("/api/v1/feeds", [feed: [title: "", url: ""]])

    response = json_response(conn, 400)
    assert %{"errors" => %{"title" => _, "url" => _}} = response
  end
end
