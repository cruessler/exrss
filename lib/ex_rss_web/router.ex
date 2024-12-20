defmodule ExRssWeb.Router do
  use ExRssWeb, :router

  @api_token_salt "user"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {ExRssWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug ExRssWeb.Plug.AssignDefaults
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

    scope "/" do
      pipe_through :authenticated

      scope "/feeds" do
        live "/", FeedLive.Index, :index
        live "/new", FeedLive.New, :new
      end
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
