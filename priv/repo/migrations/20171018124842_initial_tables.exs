defmodule ExAudit.Test.Repo.Migrations.InitialTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:email, :string)
      add(:avatars, :map)

      timestamps(type: :utc_datetime)
    end

    create table(:blog_post) do
      add(:title, :string)
      add(:author_id, references(:users, on_update: :update_all, on_delete: :delete_all))
      add(:sections, :map)

      timestamps(type: :utc_datetime)
    end

    create table(:tags) do
      add(:name, :string)

      timestamps(type: :utc_datetime)
    end

    create table(:posts_in_tags, primary_key: false) do
      add(:tag_id, references(:tags, on_update: :update_all, on_delete: :delete_all),
        primary_key: true
      )

      add(:blog_post_id, references(:blog_post, on_update: :update_all, on_delete: :delete_all),
        primary_key: true
      )
    end

    create table(:comments) do
      add(:author_id, references(:users, on_update: :update_all, on_delete: :delete_all))
      add(:body, :text)
      add(:blog_post_id, references(:blog_post, on_update: :update_all, on_delete: :delete_all))

      timestamps(type: :utc_datetime)
    end
  end
end
