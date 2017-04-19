defmodule ExRss.Api.Helpers do
  alias ExRss.Plug.Api.Authorization
  alias ExRss.User.Account

  @salt "user"
  @plug Authorization.init(@salt)
  @account %Account{id: 1}

  def with_authorization(conn) do
    token = Phoenix.Token.sign(ExRss.Endpoint, @salt, @account)

    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
    |> Authorization.call(@plug)
  end
end
