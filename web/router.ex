defmodule ExRss.Router do
  use ExRss.Web, :router

  @api_token_salt "user"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug ExRss.Plug.AssignDefaults
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug ExRss.Plug.Api.Authorization, @api_token_salt
  end

  pipeline :authenticated do
    plug ExRss.Plug.RememberUser
    plug ExRss.Plug.Authentication, "/"
    plug ExRss.Plug.AssignApiToken, @api_token_salt
  end

  scope "/", ExRss do
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
        resources "/", FeedController, only: [:index]

        get "/new", FeedController, :new
      end
    end
  end

  scope "/api", ExRss.Api do
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

  # Other scopes may use custom stacks.
  # scope "/api", ExRss do
  #   pipe_through :api
  # end
end
