defmodule ExRssWeb.Plug.Api.Authorization do
  import Plug.Conn

  @context ExRssWeb.Endpoint

  # 1 day
  @max_age 86_400

  def init(salt) do
    salt
  end

  def call(conn, salt) do
    headers = get_req_header(conn, "authorization")

    with {:ok, account} <- verify_token(headers, salt) do
      assign(conn, :current_account, account)
    else
      _ ->
        conn
        |> resp(:unauthorized, "")
        |> halt
    end
  end

  defp verify_token(["Bearer " <> token], salt) do
    Phoenix.Token.verify(@context, salt, token, max_age: @max_age)
  end

  defp verify_token(_, _) do
    {:error, :no_token}
  end
end
