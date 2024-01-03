defmodule ExRssWeb.Api.V1.EntryController do
  use ExRssWeb, :controller

  alias ExRss.Entry
  alias ExRss.Feed
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
        updated_feed = Repo.get!(Feed, entry.feed_id)

        update_broadcaster =
          Application.get_env(:ex_rss, :update_broadcaster, ExRss.Crawler.UpdateBroadcaster)

        Task.Supervisor.start_child(
          ExRss.TaskSupervisor,
          update_broadcaster,
          :broadcast_update,
          [updated_feed]
        )

        json(conn, entry)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> put_view(ExRssWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, _) do
    conn
    |> resp(:bad_request, "")
    |> halt
  end
end
