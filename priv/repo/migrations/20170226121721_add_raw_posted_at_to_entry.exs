defmodule ExRss.Repo.Migrations.AddRawPostedAtToEntry do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :raw_posted_at, :string
    end
  end
end
