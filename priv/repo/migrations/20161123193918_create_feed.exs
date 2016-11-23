defmodule ExRss.Repo.Migrations.CreateFeed do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :title, :string
      add :url, :string

      timestamps()
    end

  end
end
