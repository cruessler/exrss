defmodule ExRssWeb.PageController do
  use ExRssWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
