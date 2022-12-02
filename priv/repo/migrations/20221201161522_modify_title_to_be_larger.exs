defmodule ExRss.Repo.Migrations.ModifyTitleToBeLarger do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      modify :title, :string, size: 1024, from: :string
    end
  end
end
