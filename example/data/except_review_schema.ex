defmodule ExAudit.Test.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field(:text, :string)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:text])
    |> validate_required(:text)
  end
end
