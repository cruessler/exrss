defmodule ExRss.Plug.AssignApiToken do
  import Plug.Conn

  alias ExRss.User
  alias ExRss.User.Account

  @context ExRss.Endpoint

  def init(salt) do
    salt
  end

  def call(conn, salt) do
    if %User{id: id} = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(@context, salt, %Account{id: id})

      assign(conn, :api_token, token)
    else
      conn
    end
  end
end
