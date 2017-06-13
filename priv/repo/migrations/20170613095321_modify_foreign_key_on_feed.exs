defmodule ExRss.Repo.Migrations.ModifyForeignKeyOnFeed do
  use Ecto.Migration

  def change do
    drop index(:feeds, :url)
    create index(:feeds, [:user_id, :url], unique: true)
  end
end
