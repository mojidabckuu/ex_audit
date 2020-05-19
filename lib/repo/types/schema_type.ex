defmodule ExAudit.Type.Schema do
  use Ecto.Type

  def type, do: :string

  def cast(schema) when is_atom(schema) do
    {:ok, schema}
  end

  def cast(schema) when is_binary(schema) do
    {:ok, String.to_atom(schema)}
  end

  def cast(_), do: :error

  def load(schema) do
    {:ok, String.to_atom(schema)}
  end

  def dump(schema) when is_atom(schema) do
    {:ok, Atom.to_string(schema)}
  end

  def dump(schema) when is_binary(schema) do
    {:ok, schema}
  end
end
