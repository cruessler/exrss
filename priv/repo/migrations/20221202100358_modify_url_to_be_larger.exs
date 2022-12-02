defmodule ExRss.Repo.Migrations.ModifyUrlToBeLarger do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      modify :url, :string, size: 1024, from: :string
    end
  end
end
