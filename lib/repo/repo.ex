defmodule ExAudit.Repo do
  @moduledoc """
  Adds ExAudit version tracking to your Ecto.Repo actions. The following functions are
  extended to detect if the given struct or changeset is in the list of :tracked_schemas
  given in :ex_audit config:

    insert: 2,
    update: 2,
    insert_or_update: 2,
    delete: 2,
    insert!: 2,
    update!: 2,
    insert_or_update!: 2,
    delete!: 2

  If the given struct or changeset is not tracked then the original function from Ecto.Repo is
  executed, i.e., the functions are marked as overridable and the overrided implementations
  call `Kernel.super/1` when the given struct or changeset is not tracked.

  ## How to use it.

  Just `use ExAudit.Repo` after `Ecto.Repo`

    ```elixir
    defmodule MyApp.Repo do
      use Ecto.Repo,
        otp_app: :my_app,
        adapter: Ecto.Adapters.Postgres

      use ExAudit.Repo
    end
    ```

  ## Shared options

  All normal Ecto.Repo options will work the same, however, there are additional options specific to ex_audit:

   * `:ex_audit_custom` - Keyword list of custom data that should be placed in new version entries. Entries in this
     list overwrite data with the same keys from the ExAudit.track call
   * `:ignore_audit` - If true, ex_audit will not track changes made to entities
  """

  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour ExAudit.Repo

      @tracker_repo Keyword.get(unquote(opts), :tracker_repo)

      def tracker_repo, do: @tracker_repo

      # These are the Ecto.Repo functions that ExAudit "extends" but these are not
      # marked as overridable in Ecto.Repo. (ecto v3.4.2)
      defoverridable(
        insert: 2,
        update: 2,
        insert_or_update: 2,
        delete: 2,
        insert!: 2,
        update!: 2,
        insert_or_update!: 2,
        delete!: 2
      )

      defp tracked?(struct_or_changeset, opts) do
        if not Process.get(:ignore_audit, false) do
          tracked_schemas = Application.get_env(:ex_audit, :tracked_schemas)

          schema =
            case struct_or_changeset do
              %Ecto.Changeset{} = changeset ->
                Map.get(changeset.data, :__struct__)

              _ ->
                Map.get(struct_or_changeset, :__struct__)
            end

          if tracked_schemas do
            schema in tracked_schemas
          end || true
        end || false
      end

      @compile {:inline, tracked?: 2}

      defp wrap_ignore(struct, opts, func) do
        prev_val = Process.get(:ignore_audit)

        IO.puts("before #{struct.__struct__} #{tracked?(struct, opts)} #{inspect self()}")

        if opts != nil && Keyword.get(opts, :ignore_audit) != nil do
          Process.put(:ignore_audit, Keyword.get(opts, :ignore_audit))
        end

        result = func.()

        if prev_val do
          Process.put(:ignore_audit, prev_val)
        else
          Process.delete(:ignore_audit)
        end

        IO.puts("after #{struct.__struct__} #{tracked?(struct, opts)} #{inspect self()}")

        result
      end

      def insert(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          IO.puts "insert call #{struct.__struct__}"
          if tracked?(struct, opts) do
            ExAudit.Schema.insert(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      def update(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          if tracked?(struct, opts) do
            ExAudit.Schema.update(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      def insert_or_update(changeset, opts) do
        wrap_ignore(changeset, opts, fn ->
          if tracked?(changeset, opts) do
            ExAudit.Schema.insert_or_update(
              __MODULE__,
              get_dynamic_repo(),
              changeset,
              opts
            )
          else
            super(changeset, opts)
          end
        end)
      end

      def delete(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          if tracked?(struct, opts) do
            ExAudit.Schema.delete(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      def insert!(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          IO.puts "insert! call #{struct.__struct__}"

          if tracked?(struct, opts) do
            ExAudit.Schema.insert!(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      def update!(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          if tracked?(struct, opts) do
            ExAudit.Schema.update!(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      def insert_or_update!(changeset, opts) do
        wrap_ignore(changeset, opts, fn ->
          if tracked?(changeset, opts) do
            ExAudit.Schema.insert_or_update!(
              __MODULE__,
              get_dynamic_repo(),
              changeset,
              opts
            )
          else
            super(changeset, opts)
          end
        end)
      end

      def delete!(struct, opts) do
        wrap_ignore(struct, opts, fn ->
          if tracked?(struct, opts) do
            ExAudit.Schema.delete!(
              __MODULE__,
              get_dynamic_repo(),
              struct,
              opts
            )
          else
            super(struct, opts)
          end
        end)
      end

      # ExAudit.Repo behaviour
      def history(struct, opts \\ []) do
        ExAudit.Queryable.history(__MODULE__, struct, opts)
      end

      def revert(version, opts \\ []) do
        ExAudit.Queryable.revert(__MODULE__, version, opts)
      end
    end
  end

  @doc """
  Gathers the version history for the given struct, ordered by the time the changes
  happened from newest to oldest.
  ### Options
   * `:render_structs` if true, renders the _resulting_ struct of the patch for every version in its history.
     This will shift the ids of the versions one down, so visualisations are correct and corresponding "Revert"
     buttons revert the struct back to the visualized state.
     Will append an additional version that contains the oldest ID and the oldest struct known. In most cases, the
     `original` will be `nil` which means if this version would be reverted, the struct would be deleted.
     `false` by default.
  """
  @callback history(struct, opts :: list) :: [version :: struct]

  @doc """
  Undoes the changes made in the given version, as well as all of the following versions.
  Inserts a new version entry in the process, with the `:rollback` flag set to true
  ### Options
   * `:preload` if your changeset depends on assocs being preloaded on the struct before
     updating it, you can define a list of assocs to be preloaded with this option
  """
  @callback revert(version :: struct, opts :: list) ::
              {:ok, struct} | {:error, changeset :: Ecto.Changeset.t()}
end
