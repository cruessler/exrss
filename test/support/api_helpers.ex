defmodule ExRss.Api.Helpers do
  alias ExRss.Plug.Api.Authorization
  alias ExRss.User
  alias ExRss.User.Account

  @salt "user"
  @plug Authorization.init(@salt)

  def with_authorization(conn, %User{id: id}) do
    account = %Account{id: id}
    token = Phoenix.Token.sign(ExRss.Endpoint, @salt, account)

    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
    |> Authorization.call(@plug)
  end
end
