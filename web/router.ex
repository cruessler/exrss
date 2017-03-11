defmodule ExRss.Router do
  use ExRss.Web, :router

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

    plug ExRss.Plug.Api.Authorization, "user"
  end

  pipeline :authenticated do
    plug ExRss.Plug.Authentication, "/"
  end

  scope "/", ExRss do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/session",
      SessionController,
      only: [ :create, :new, :delete ],
      singleton: true

    resources "/users", UserController, only: [ :create, :new ]

    scope "/" do
      pipe_through :authenticated

      resources "/feeds", FeedController, only: [ :index ]
    end
  end

  scope "/api", ExRss.Api do
    pipe_through :api

    scope "/v1", V1 do
      resources "/entries", EntryController, only: [ :update ]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExRss do
  #   pipe_through :api
  # end
end
