defmodule Armitage.Release do
  @moduledoc """
  Set up the database and run migrations.
  Run with: `bin/armitage eval 'Armitage.Release.some_function'`
  """

  alias Armitage.Repo
  alias Armitage.ReadWise
  import Ecto.Query

  def migrate do
    load_app()
    for repo <- repos() do
      case Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true)) do
      {:ok, _, _} -> :ok
      {:error, :already_up} -> IO.puts("Migrations already up-to-date")
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
    link_highlights_to_books()
    tidy_forwarded_books()
  end

  def sync_new_data do
    load_app()
    ensure_started()
    Armitage.ReadWise.sync_new_highlights()
    Armitage.ReadWise.sync_new_books()
    link_highlights_to_books()
    tidy_forwarded_books()
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

  def alter_books_url_length do
    load_app()
    for repo <- repos() do
      IO.puts("➡️  Starting #{inspect(repo)}")

      case repo.start_link(pool_size: 1) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        {:error, reason} -> raise "Failed to start repo: #{inspect(reason)}"
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
    ensure_started()
    IO.puts("WARNING: Resetting all highlight and book data...")
    Repo.delete_all(Armitage.Highlight)
    Repo.delete_all(Armitage.Book)
    seed()
  end

  def backfill_slugs do
    Repo.start_link()

    Repo.transaction(fn ->
      Repo.all(
        from b in Armitage.Book,
        where: is_nil(b.slug) and b.category in ["books", "articles"]
      )
      |> Enum.each(fn book ->
        changeset = Armitage.Book.changeset(book, %{})
        case Repo.update(changeset) do
          {:ok, _updated} ->
            IO.puts("Slug added for: #{book.title}")
          {:error, changeset} ->
            IO.puts("Failed for: #{book.title}")
            IO.inspect(changeset.errors)
        end
      end)
    end)
  end

  def link_highlights_to_books do
    import Ecto.Query

    Repo.start_link()

    Repo.transaction(fn ->
      from(h in Armitage.Highlight, where: is_nil(h.book_id))
      |> Repo.all()
      |> Enum.each(fn highlight ->
        case Repo.get_by(Armitage.Book, readwise_book_id: highlight.readwise_book_id) do
          nil ->
            IO.puts("No book found for highlight #{highlight.id} (readwise_book_id: #{highlight.readwise_book_id})")

          book ->
            highlight
            |> Ecto.Changeset.change(book_id: book.id)
            |> Repo.update()
        end
      end)
    end)
  end

  def tidy_forwarded_books do
    import Ecto.Query

    from(b in Armitage.Book,
      where: like(b.title, "Fwd:%") and b.author == "alex@pikori.com"
    )
    |> Armitage.Repo.delete_all()
  end


end

