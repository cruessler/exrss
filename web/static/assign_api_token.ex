defmodule ExRss.Plug.AssignApiToken do
  import Plug.Conn

  @context ExRss.Endpoint

  def init(salt) do
    salt
  end

  def call(conn, salt) do
    if data = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(@context, salt, data)

      assign(conn, :api_token, token)
    else
      conn
    end
  end
end
