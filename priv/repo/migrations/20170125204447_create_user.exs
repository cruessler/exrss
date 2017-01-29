defmodule ExRss.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :hashed_password, :string

      timestamps()
    end

    alter table(:feeds) do
      add :user_id, references(:users)
    end

    create index(:feeds, [:user_id])
  end
end
