defmodule ExRss.Plug.AssignDefaults do
  import Plug.Conn

  def init(params), do: params

  def call(conn, _params), do: assign_defaults(conn)

  defp assign_defaults(conn) do
    # Setting these variables to nil enables checking for existence via
    # `@current_user` in templates. If the variables would not be set, an
    # error would be thrown.
    assign(conn, :current_user, get_session(conn, :current_user))
  end
end
