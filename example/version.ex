defmodule ExAudit.Test.Version do
  use Ecto.Schema
  import Ecto.Changeset

  schema "versions" do
    field :patch, ExAudit.Type.PatchMap
    field :entity_id, :integer
    field :entity_schema, ExAudit.Type.Schema
    field :action, ExAudit.Type.Action
    field :recorded_at, :naive_datetime_usec
    field :rollback, :boolean, default: false
    field :version, Ecto.UUID

    # custom fields
    belongs_to :actor, ExAudit.Test.User
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:patch, :entity_id, :entity_schema, :action, :recorded_at, :rollback])
    |> cast(params, [:actor_id]) # custom fields
  end
end
