defmodule ExRss.PageController do
  use ExRss.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
