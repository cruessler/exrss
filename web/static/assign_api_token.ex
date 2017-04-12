defmodule ExRss.Plug.AssignApiToken do
  import Plug.Conn

  alias ExRss.User.Account

  @context ExRss.Endpoint

  def init(salt) do
    salt
  end

  def call(conn, salt) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(@context, salt, %Account{id: current_user.id})

      assign(conn, :api_token, token)
    else
      conn
    end
  end
end
