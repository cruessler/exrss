defmodule ExRss.Repo.Migrations.AddLastSuccessfulUpdateAtOnFeed do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :last_successful_update_at, :utc_datetime
    end
  end
end
