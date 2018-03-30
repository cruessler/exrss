defmodule ExRss.Repo.Migrations.CascadeDelete do
  use Ecto.Migration

  def up do
    drop constraint(:entries, "entries_feed_id_fkey")

    alter table(:entries) do
      modify :feed_id, references(:feeds, on_delete: :delete_all), null: false
    end

    drop(constraint(:feeds, "feeds_user_id_fkey"))

    alter table(:feeds) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end

  def down do
    drop constraint(:entries, "entries_feed_id_fkey")

    alter table(:entries) do
      modify :feed_id, references(:feeds), null: false
    end

    drop constraint(:feeds, "feeds_user_id_fkey")

    alter table(:feeds) do
      modify :user_id, references(:users), null: false
    end
  end
end
