defmodule ExRssWeb.Api.V1.EntryController do
  use ExRssWeb, :controller

  alias ExRss.Entry
  alias ExRss.Repo
  alias ExRss.User

  def update(conn, %{"id" => id, "entry" => entry_params}) do
    changeset =
      Repo.get!(User, conn.assigns.current_account.id)
      |> assoc(:entries)
      |> Repo.get(id)
      |> Entry.changeset(entry_params)

    case Repo.update(changeset) do
      {:ok, entry} ->
        json(conn, entry)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render(ExRssWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, _) do
    conn
    |> resp(:bad_request, "")
    |> halt
  end
end
