defmodule ExRssWeb.UserAuth do
  use ExRssWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias ExRss.{Repo, User}

  # TODO 2024-12-24
  # - Replace code for getting the current user when a session is given.
  # - Adapt paths for logging in (currently, `/session/new` while the generator
  #   uses `/users/log_in`).

  @doc """
  Authenticates the user by looking into the session and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    # 2024-12-24
    # This is not what the generator creates (this is why the doc not fully
    # matches what the function does). It is code taken from the existing
    # `Authentication` that is used here to make starting the migration easier.
    user =
      with %User{id: id} <- get_session(conn, :current_user) do
        Repo.get(User, id)
      else
        _ ->
          nil
      end

    assign(conn, :current_user, user)
  end

  @doc """
  Handles mounting and authenticating the `current_user` in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns `current_user` to socket assigns based on
      `user_token`, or `nil` if there's no `user_token` or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session, and
      assigns the `current_user` to socket assigns based on `user_token`.
      Redirects to login page if there's no logged in user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the
      session. Redirects to `signed_in_path` if there's a logged in user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate the
  `current_user`:

      defmodule LightweightTodoWeb.PageLive do
        use LightweightTodoWeb, :live_view

        on_mount {LightweightTodoWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the `on_mount` callback:

      live_session :authenticated, on_mount: [{LightweightTodoWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: log_in_path())

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path())}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      # 2024-12-24
      # This is not what the generator creates (this is why the doc not fully
      # matches what the function does). It is code taken from the existing
      # `Authentication` that is used here to make starting the migration
      # easier.
      with %User{id: id} <- session["current_user"] do
        Repo.get(User, id)
      else
        _ ->
          nil
      end
    end)
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before they use the
  application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: log_in_path())
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp log_in_path(), do: ~p"/session/new"
  defp signed_in_path(), do: ~p"/feeds"
end
