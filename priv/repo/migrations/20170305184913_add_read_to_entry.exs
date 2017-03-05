defmodule ExRss.Repo.Migrations.AddReadToEntry do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :read, :boolean
    end

    create index(:entries, [:read])
  end
end
