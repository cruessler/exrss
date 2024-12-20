defmodule ExRssWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use ExRssWeb, :controller
      use ExRssWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias ExRss.Repo
      import Ecto
      import Ecto.Query

      import Plug.Conn
      import ExRssWeb.Gettext

      unquote(verified_routes())
    end
  end

  # 2024-12-03
  # `view` was generated before Phoenix 1.7 and would not be generated by
  # Phoenix 1.7. It is kept around to keep existing code working and to keep
  # the initial migration to LiveView small.
  def view do
    quote do
      use Phoenix.View, root: "lib/ex_rss_web/templates", namespace: ExRssWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1]

      # HTML escaping functionality
      import Phoenix.HTML

      import ExRssWeb.ErrorHelpers
      import ExRssWeb.Gettext

      import ExRssWeb.AppView

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ExRssWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias ExRss.Repo
      import Ecto
      import Ecto.Query
      import ExRssWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      import ExRssWeb.CoreComponents
      import ExRssWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ExRssWeb.Endpoint,
        router: ExRssWeb.Router,
        statics: ExRssWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
