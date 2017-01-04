defmodule ExRss.Repo.Migrations.AddIndexOnFeed do
  use Ecto.Migration

  def change do
    create index(:feeds, [:url], unique: true)
  end
end
