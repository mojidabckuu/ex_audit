defmodule ExAudit.Type.Table do
  use Ecto.Type

  def type, do: :string

  def cast(schema) when is_atom(schema) do
    {:ok, schema}
  end

  def cast(table_name) when is_binary(table_name) do
    {:ok, table_name}
  end

  def cast(_), do: :error

  def load(table) do
    {:ok, table}
  end

  def dump(schema) when is_atom(schema) do
    {:ok, schema.__schema__(:source)}
  end

  def dump(table) when is_binary(table) do
    {:ok, table}
  end
end
