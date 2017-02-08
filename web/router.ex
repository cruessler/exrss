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
  end

  scope "/", ExRss do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/session",
      SessionController,
      only: [ :create, :new, :delete ],
      singleton: true

    resources "/users", UserController, only: [ :create, :new ]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExRss do
  #   pipe_through :api
  # end
end
