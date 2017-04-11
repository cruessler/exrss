defmodule ExRss.Api.V1.EntryController do
  use ExRss.Web, :controller

  alias ExRss.Entry
  alias ExRss.Repo

  def update(conn, %{"id" => id, "entry" => entry_params}) do
    changeset =
      conn.assigns.current_user
      |> assoc(:entries)
      |> Repo.get(id)
      |> Entry.changeset(entry_params)

    case Repo.update(changeset) do
      {:ok, entry} ->
        json(conn, entry)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render(ExRss.ChangesetView, "error.json", changeset: changeset)
    end
  end
  def update(conn, _) do
    conn
    |> put_status(:bad_request)
    |> halt
  end
end
