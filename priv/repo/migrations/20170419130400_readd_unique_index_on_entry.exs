defmodule ExRss.Repo.Migrations.ReaddUniqueIndexOnEntry do
  use Ecto.Migration

  def change do
    create index(:entries, [:feed_id, :url], unique: true)
  end
end
