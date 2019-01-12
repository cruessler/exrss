defmodule ExRss.Repo.Migrations.AddRememberMeTokenOnUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :remember_me_token, :text
    end

    create index(:users, [:remember_me_token])
  end
end
