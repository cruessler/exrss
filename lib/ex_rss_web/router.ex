defmodule ExRssWeb.Router do
  use ExRssWeb, :router

  import ExRssWeb.UserAuth

  @api_token_salt "user"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {ExRssWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
    # Use the default browser stack
    pipe_through :browser

    get "/", PageController, :index

    resources "/session",
              SessionController,
              only: [:create, :new, :delete],
              singleton: true

    resources "/users", UserController, only: [:create, :new]
  end

  scope "/", ExRssWeb do
    # 2024-12-24
    # `:fetch_current_user`, at some point, can probably be moved to the
    # pipeline `:browser` (that’s where the generator puts it). It is here
    # because this is the least impactful place when I started the migration to
    # the generated auth code.
    pipe_through [:browser, :fetch_current_user, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ExRssWeb.UserAuth, :ensure_authenticated}] do
      live "/feeds", FeedLive.Index, :index
      live "/feeds/new", FeedLive.New, :new
    end
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
