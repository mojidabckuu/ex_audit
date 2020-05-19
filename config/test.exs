use Mix.Config

config :ex_audit, ExAudit.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres",
  password: "postgres",
  database: "ex_audit_test",
  hostname: "localhost",
  pool_size: 5

config :ex_audit, ExAudit.Test.TrackerRepo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres",
  password: "postgres",
  database: "ex_audit_tracker_test",
  hostname: "localhost",
  pool_size: 5

config :logger, level: :debug

config :ex_audit,
  ecto_repos: [ExAudit.Test.Repo, ExAudit.Test.TrackerRepo],
  version_schema: ExAudit.Test.Version,
  tracked_schemas: [
    ExAudit.Test.User,
    ExAudit.Test.BlogPost,
    ExAudit.Test.BlogPost.Section,
    ExAudit.Test.Comment
  ],
  scalar_types: [NaiveDateTime, DateTime, Decimal]
