defmodule ExAudit.Test.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {ExAudit.Tracker, except: [:transient_field]}

  schema "users" do
    field(:email, :string)
    field(:name, :string)

    field(:transient_field, :integer)

    embeds_many(:avatars, ExAudit.Test.Avatar)

    has_many(:groups, ExAudit.Test.UserGroup)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name])
    |> cast_embed(:avatars)
  end
end
