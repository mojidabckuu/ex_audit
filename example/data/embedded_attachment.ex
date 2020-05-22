defmodule ExAudit.Test.Avatar do
  use Ecto.Schema

  import Ecto.Changeset

  @derive Jason.Encoder
  embedded_schema do
    field :url, :string
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:url])
    |> validate_length(:url, min: 1)
    |> validate_required(:url)
  end
end
