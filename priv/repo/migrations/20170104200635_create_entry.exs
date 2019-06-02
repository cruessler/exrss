defmodule ExRss.Repo.Migrations.CreateEntry do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :feed_id, references(:feeds)

      add :url, :string
      add :title, :string

      add :posted_at, :utc_datetime

      timestamps()
    end

    create index(:entries, [:feed_id, :url], unique: true)
  end
end
