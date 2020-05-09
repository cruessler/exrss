defmodule ExRss.Repo.Migrations.ModifyForeignKeys do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      remove :user_id
    end

    alter table(:feeds) do
      add :user_id, references(:users), null: false
    end

    alter table(:entries) do
      remove :feed_id
    end

    alter table(:entries) do
      add :feed_id, references(:feeds), null: false
    end
  end
end
