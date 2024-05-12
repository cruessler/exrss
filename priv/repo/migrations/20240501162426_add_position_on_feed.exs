defmodule ExRss.Repo.Migrations.AddPositionOnFeed do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :position, :integer, null: true
    end
  end
end
