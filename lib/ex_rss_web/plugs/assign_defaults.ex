defmodule ExRssWeb.Plug.AssignDefaults do
  import Plug.Conn

  def init(params), do: params

  def call(conn, _params), do: assign_defaults(conn)

  defp assign_defaults(conn) do
    # Setting this variable to nil enables checking for existence via
    # `@current_user` in templates. If the variable would not be set, an
    # error would be thrown.
    conn
    |> assign(:current_user, nil)
  end
end
