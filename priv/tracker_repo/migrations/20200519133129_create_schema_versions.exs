defmodule ExAudit.Test.TrackerRepo.Migrations.CreateSchemaVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      # The patch in Erlang External Term Format
      add :patch, :json

      # supports UUID and other types as well
      add :entity_id, :integer

      # name of the table the entity is in
      add :entity_schema, :string

      # type of the action that has happened to the entity (created, updated, deleted)
      add :action, :string

      # when has this happened
      add :recorded_at, :naive_datetime_usec

      # was this change part of a rollback?
      add :rollback, :boolean, default: false

      # optional fields that you can define yourself
      # for example, it's a good idea to track who did the change
      add :actor_id, :integer
      add :version, :uuid
    end
  end
end
