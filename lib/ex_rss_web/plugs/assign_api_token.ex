defmodule ExRssWeb.Plug.AssignApiToken do
  import Plug.Conn

  alias ExRss.User
  alias ExRss.User.Account

  @context ExRssWeb.Endpoint

  def init(salt) do
    salt
  end

  def call(conn, salt) do
    if %User{id: id} = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(@context, salt, %Account{id: id})

      conn
      # 2024-12-03
      # `assign` is used to assign to `conn.assigns` in order to have the token
      # available in regular templates.
      |> assign(:api_token, token)
      # `put_session` is used to have the token available in LiveViews’
      # `mount`.
      |> put_session(:api_token, token)
    else
      conn
    end
  end
end
