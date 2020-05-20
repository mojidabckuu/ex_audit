defmodule ExAudit.CustomData do
  use GenServer

  @moduledoc """
  ETS table that stores custom data for pids
  """

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    ets = :ets.new(:track_by_pid, [:public])
    {:ok, ets}
  end

  def track(pid, data, opts) when is_map(data) do
    GenServer.call(__MODULE__, {:store, pid, data, opts})
  end

  def handle_call({:store, pid, data, opts}, _, ets) do
    new_data =
      case :ets.lookup(ets, pid) do
        [{_pid, old_data}] ->
          if Keyword.get(opts, :override, false) do
            data
          else
            Map.merge(old_data, data)
          end

        [] ->
          Process.monitor(pid)
          data
      end

    :ets.insert(ets, {pid, new_data})
    {:reply, :ok, ets}
  end

  def handle_call({:get, pid}, _, ets) do
    case :ets.lookup(ets, pid) do
      [] ->
        {:reply, [], ets}

      list ->
        values = Enum.flat_map(list, &elem(&1, 1))
        {:reply, values, ets}
    end
  end

  def get() do
    GenServer.call(__MODULE__, {:get, self()})
  end

  def get(pid) do
    GenServer.call(__MODULE__, {:get, pid})
  end

  def handle_info({:DOWN, _, :process, pid, _}, ets) do
    :ets.delete(ets, pid)
    {:noreply, ets}
  end
end
