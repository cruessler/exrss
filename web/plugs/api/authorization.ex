defmodule ExRss.Plug.Api.Authorization do
  import Plug.Conn

  @context ExRss.Endpoint

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
        |> put_status(:unauthorized)
        |> halt
    end
  end

  defp verify_token(["Bearer " <> token], salt) do
    Phoenix.Token.verify(@context, salt, token)
  end
  defp verify_token(_, _) do
    {:error, :no_token}
  end
end
