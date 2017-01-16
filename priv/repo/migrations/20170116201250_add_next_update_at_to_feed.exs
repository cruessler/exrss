defmodule ExRss.Repo.Migrations.AddNextUpdateAtToFeeds do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :next_update_at, :utc_datetime
    end
  end
end
