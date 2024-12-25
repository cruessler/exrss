defmodule ExRss.Repo.Migrations.AddConfirmedAtToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :confirmed_at, :naive_datetime
    end
  end
end
