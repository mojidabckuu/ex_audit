defmodule ExAudit.Test.Repo do
  use Ecto.Repo,
    otp_app: :ex_audit,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo, tracker_repo: ExAudit.Test.TrackerRepo
end

defmodule ExAudit.Test.TrackerRepo do
  use Ecto.Repo,
    otp_app: :ex_audit,
    adapter: Ecto.Adapters.Postgres

  def history(struct, opts \\ []) do
    ExAudit.Queryable.history(__MODULE__, struct, opts)
  end

  def revert(version, opts \\ []) do
    ExAudit.Queryable.revert(__MODULE__, version, opts)
  end

  def tracker_repo, do: __MODULE__
end
