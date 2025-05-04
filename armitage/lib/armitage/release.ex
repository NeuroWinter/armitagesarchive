defmodule Armitage.Release do
  @moduledoc """
  Set up the database and run migrations.
  Run with: `bin/armitage eval 'Armitage.Release.some_function'`
  """

  alias Armitage.Repo
  alias Armitage.ReadWise

  def migrate do
    load_app()
    for repo <- repos() do
      case Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true)) do
      {:ok, _, _} -> :ok
      {:error, :already_up} -> IO.puts("✅ Migrations already up-to-date")
      other -> raise "Migration failed: #{inspect(other)}"
    end
    end
  end

  def seed do
    migrate()
    alter_books_url_length()
    sync_readwise_highlights()
    sanitize_highlights()
    backfill_books()
  end

  def sanitize_highlights do
    ensure_started()
    ReadWise.sanitize_stored_highlights()
  end

  def sync_readwise_highlights do
    load_app()
    ensure_started()
    ReadWise.sync_all_highlights()
  end

  defp ensure_started do
    Application.ensure_all_started(:armitage)
    start_req_finch()
  end

  defp start_req_finch do
    case Finch.start_link(name: Req.Finch) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> raise "Failed to start Req.Finch: #{inspect(reason)}"
    end
  end

  def backfill_books do
    {:ok, _} = Application.ensure_all_started(:armitage)
    ReadWise.backfill_books_and_link_highlights()
  end

  defp repos, do: Application.fetch_env!(:armitage, :ecto_repos)

  defp migrations_path(repo), do: priv_path_for(repo, "migrations")

  defp priv_path_for(repo, filename) do
    app = Keyword.fetch!(repo.config, :otp_app)
    "#{:code.priv_dir(app)}/repo/#{filename}"
  end

  def alter_books_url_length do
    load_app()
    for repo <- repos() do
      IO.puts("➡️  Starting #{inspect(repo)}")

      case repo.start_link(pool_size: 1) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        {:error, reason} -> raise "❌ Failed to start repo: #{inspect(reason)}"
      end
    end

    Ecto.Adapters.SQL.query!(
      Repo,
      "ALTER TABLE books ALTER COLUMN url TYPE varchar(2000);",
      []
    )
    end


  defp load_app do
    Application.load(:armitage)
    for app <- [:logger, :crypto, :ssl, :telemetry, :ecto_sql, :postgrex] do
      {:ok, _} = Application.ensure_all_started(app)
    end
  end

  def reset(confirm \\ false)

  def reset(false) do
    raise """
    This will delete all books and highlights.
    If you really want to do this, call:

        Armitage.Release.reset(true)
    """
  end

  def reset(true) do
    load_app()
    IO.puts("WARNING: Resetting all highlight and book data...")
    Repo.delete_all(Armitage.Highlight)
    Repo.delete_all(Armitage.Book)
    seed()
  end

end

