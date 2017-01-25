defmodule ExRss.Repo.Migrations.AddRetriesToFeed do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :retries, :integer, default: 0
    end
  end
end
