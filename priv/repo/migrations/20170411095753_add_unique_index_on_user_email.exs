defmodule ExRss.Repo.Migrations.AddUniqueIndexOnUserEmail do
  use Ecto.Migration

  def change do
    create index(:users, [:email], unique: true)
  end
end
