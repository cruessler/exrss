defmodule ExRss.UserController do
  use ExRss.Web, :controller

  alias ExRss.User.Registration

  def new(conn, _params) do
    changeset = Registration.changeset(%Registration{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"registration" => registration_params}) do
    changeset = Registration.changeset(%Registration{}, registration_params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Your account has been registered.")
        |> redirect(to: page_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
