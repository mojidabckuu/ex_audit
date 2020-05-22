defmodule ExAudit.Type.PatchMap do
  use Ecto.Type

  def type, do: :map

  def cast(a), do: {:ok, a}

  def dump(patch) do
    IO.puts("ENCODE: #{inspect(patch)}")
    {:ok, encode(patch)}
  end

  def load(binary) do
    {:ok, decode(binary)}
  end

  defp encode({:added, value}), do: %{"a" => "add", "v" => value}
  defp encode({:removed, value}), do: %{"a" => "del", "v" => value}

  defp encode({:primitive_change, old_value, new_value}),
    do: %{
      "a" => "upd",
      "ov" => old_value,
      "v" => new_value
    }

  defp encode({:changed, changes}), do: %{"a" => "upd", "v" => encode(changes)}

  defp encode({:added_to_list, index, value}),
    do: %{
      "a" => "add",
      "idx" => index,
      "v" => value
    }

  defp encode({:removed_from_list, index, value}),
    do: %{
      "a" => "del",
      "idx" => index,
      "v" => value
    }

  defp encode({:changed_in_list, index, changes}),
    do: %{
      "a" => "upd",
      "index" => index,
      "v" => encode(changes)
    }

  defp encode(changes) when is_struct(changes) do
    changes
  end

  defp encode(changes) when is_map(changes) do
    Enum.reduce(changes, %{}, fn {key, value}, acc ->
      Map.put(acc, key, encode(value))
    end)
  end

  defp encode(changes) when is_tuple(changes) do
    changes
    |> Tuple.to_list()
    |> Enum.map(&encode/1)
  end

  defp encode(changes) when is_list(changes) do
    changes
    |> Enum.map(&encode/1)
  end

  defp encode(value), do: value

  defp decode(%{"a" => "add", "idx" => index, "v" => value}) do
    {:added_to_list, index, value}
  end

  defp decode(%{"a" => "del", "idx" => index, "v" => value}) do
    {:remove_from_list, index, value}
  end

  defp decode(%{"a" => "upd", "idx" => index, "v" => value}) do
    {:changed_in_list, index, decode(value)}
  end

  defp decode(%{"a" => "add", "v" => value}) do
    {:added, value}
  end

  defp decode(%{"a" => "del", "v" => value}) do
    {:removed, value}
  end

  defp decode(%{"a" => "upd", "v" => new_value, "ov" => old_value}) do
    {:primitive_change, old_value, new_value}
  end

  defp decode(%{"a" => "upd", "v" => value}) do
    {:changed, decode(value)}
  end

  defp decode(value) when is_map(value) do
    Enum.reduce(value, %{}, fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), decode(value))
    end)
  end

  defp decode(value) when is_list(value) do
    first_value = List.first(value)

    if is_binary(first_value) do
      key = List.first(value) |> String.to_atom()
      value = List.replace_at(value, 0, key)

      value
      |> Enum.map(&decode/1)
      |> List.to_tuple()
    else
      value
      |> Enum.map(&decode/1)
      |> List.to_tuple()
    end
  end

  defp decode(value), do: value
end
