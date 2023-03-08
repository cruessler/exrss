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

  # `exrss` has not been set up to use verified routes yet. To change that,
  # follow [the guide][1].
  #
  # [1]: https://gist.github.com/chrismccord/00a6ea2a96bc57df0cce526bd20af8a7

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

      import ExRssWeb.Gettext
      alias ExRssWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/ex_rss_web/templates", namespace: ExRssWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import ExRssWeb.ErrorHelpers
      import ExRssWeb.Gettext
      alias ExRssWeb.Router.Helpers, as: Routes

      import ExRssWeb.AppView
    end
  end

  def router do
    quote do
      use Phoenix.Router
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

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
