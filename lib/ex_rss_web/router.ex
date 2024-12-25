defmodule ExRssWeb.Router do
  use ExRssWeb, :router

  import ExRssWeb.UserAuth

  @api_token_salt "user"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    # TODO 2024-12-25
    # `fetch_flash` can probably be removed as it seems to have been superseded
    # by `fetch_live_flash`.
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {ExRssWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug ExRssWeb.Plug.Api.Authorization, @api_token_salt
  end

  pipeline :authenticated do
    plug ExRssWeb.Plug.RememberUser
    plug ExRssWeb.Plug.Authentication, "/"
    plug ExRssWeb.Plug.AssignApiToken, @api_token_salt

    plug :put_user_token
  end

  scope "/", ExRssWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ExRssWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ExRssWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ExRssWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/feeds", FeedLive.Index, :index
      live "/feeds/new", FeedLive.New, :new
    end
  end

  scope "/", ExRssWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ExRssWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end

    get "/", PageController, :index
  end

  scope "/api", ExRssWeb.Api do
    pipe_through :api

    scope "/v1", V1 do
      resources "/entries", EntryController, only: [:update]

      get "/feeds/discover", FeedController, :discover

      scope "/feeds" do
        resources "/", FeedController, only: [:index, :create, :update, :delete]

        get "/only_unread_entries", FeedController, :only_unread_entries
      end
    end
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)

      assign(conn, :user_token, token)
    else
      conn
    end
  end
end
