defmodule ExAudit do
  use Application

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(ExAudit.CustomData, [])
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Tracks the given keyword list of data for the current process
  """
  def track(data, opts \\ []) do
    track_pid(self(), data, opts)
  end

  @doc """
  Tracks the given keyword list of data for the given process
  """
  def track_pid(pid, data, opts \\ []) do
    ExAudit.CustomData.track(pid, data, opts)
  end
end
