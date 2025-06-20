defmodule Armitage.ReadWise do
  @moduledoc """
  This is the module that holds all the interactions with the Readwise API.
  """
  require Req
  import Ecto.Query

  alias Armitage.Book
  alias Armitage.Repo
  alias Armitage.Highlight
  alias Armitage.TextUtils

  # Type specifications for clarity and maintainability
  @type tag :: %{
          id: integer(),
          name: String.t()
        }

  @type highlight :: %{
          id: integer(),
          text: String.t(),
          note: String.t() | nil,
          location: integer() | String.t(),
          location_type: String.t(),
          highlighted_at: String.t() | nil,
          url: String.t() | nil,
          color: String.t() | nil,
          updated: String.t(),
          book_id: integer(),
          tags: list(tag())
        }

  @type highlights_response :: %{
          count: integer(),
          next: String.t() | nil,
          previous: String.t() | nil,
          results: list(highlight())
        }

  # This is what the book endpoint returns:
  @type book_details :: %{
          id: integer(),
          title: String.t(),
          author: String.t(),
          category: String.t(),
          source: String.t(),
          num_highlights: integer(),
          last_highlight_at: String.t(),
          updated: String.t(),
          cover_image_url: String.t(),
          highlights_url: String.t(),
          source_url: String.t() | nil,
          asin: String.t(),
          tags: list(tag()),
          document_note: String.t() | nil
        }

  # Access token retrieval and setup
  @spec get_access_token() :: String.t()
  def get_access_token() do
    Application.get_env(:armitage, :readwise_access_token)
    |> case do
      nil -> raise "Access token not configured. Please call `set_access_token/1`."
      token -> token
    end
  end

  @spec set_access_token(String.t()) :: :ok
  def set_access_token(token) do
    Application.put_env(:armitage, :readwise_access_token, token)
  end

  # Fetch a random highlight
  @spec get_random_highlight() :: {:ok, Armitage.Highlight.t()} | {:error, any()}
  def get_random_highlight() do

    query = from h in Armitage.Highlight, preload: [:book]

    case Armitage.Repo.all(query) do
      [] -> {:error, "No highlights available"}
      highlights -> {:ok, Enum.random(highlights)}
    end
  end

  @spec sanitize_book_details(book_details()) :: book_details()
  defp sanitize_book_details(%{"source_url" => url} = highlight) when is_binary(url) do
    highlight
    |> remove_disallowed_prefixes()
    |> remove_disallowed_hosts()
  end

  defp sanitize_book_details(highlight), do: highlight

  @spec remove_disallowed_prefixes(book_details()) :: book_details()
  defp remove_disallowed_prefixes(%{"source_url" => url} = highlight) do
    disallowed_prefixes = ["private://", "internal://", "file://", "mailto:"]

    if Enum.any?(disallowed_prefixes, fn prefix -> String.starts_with?(url, prefix) end) do
      Map.delete(highlight, "source_url")
    else
      highlight
    end
  end

  defp remove_disallowed_prefixes(highlight), do: highlight

  defp remove_disallowed_hosts(%{"source_url" => url} = highlight) do
    disallowed_hosts = ["readwise.com", "localhost", "readwise.io"]

    case URI.parse(url) do
      %URI{host: host} when is_binary(host) ->
        if Enum.member?(disallowed_hosts, host) do
          Map.delete(highlight, "source_url")
        else
          highlight
        end
      _ ->
        highlight
    end
  end

  defp remove_disallowed_hosts(highlight), do: highlight

  @doc """
  Sanitize the highlight text by removing unwanted elements and converting markdown links to HTML.
  """
  @spec sanitize_highlight_text(Armitage.Highlight.t()) :: Armitage.Highlight.t()
  def sanitize_highlight_text(%Armitage.Highlight{text: text} = highlight) when is_binary(text) do
    updated_text =
      text
      |> TextUtils.normalize_quotes()
      |> TextUtils.remove_bad_references()
      |> TextUtils.convert_markdown_links()
      |> TextUtils.remove_internal_links()
      |> TextUtils.remove_private_href_links()

    %Armitage.Highlight{highlight | text: updated_text}
  end

  def sanitize_highlight_text(highlight), do: highlight

  # TODO: change to a real type
  @spec fetch_book_info_by_id(integer()) :: {:ok, book_details()} | {:error, any()}
  defp fetch_book_info_by_id(id) do
    url = "https://readwise.io/api/v2/books/#{id}/"

    case make_request(url) do
      {:ok, book} -> {:ok, book}
      {:error, error} -> {:error, error}
    end
  end

  @spec make_request(String.t()) :: {:ok, map()} | {:error, any()}
  defp make_request(url) do
    Req.get(url,
      headers: [{"Authorization", "Token #{get_access_token()}"}]
    )
    |> case do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, %{status: status, body: body}}
      {:error, error} -> {:error, "Request error: #{inspect(error)}"}
    end
  end

  @spec sync_all_highlights() :: :ok
  def sync_all_highlights do
    sync_all_highlights_paginated(1)
  end

  defp paginate_api(url, page \\ 1, callback) do
    full_url = "#{url}?page=#{page}&page_size=100"

    case make_request(full_url) do
      {:ok, %{"results" => results, "next" => next}} ->
        Enum.each(results, callback)
        if next, do: paginate_api(url, page + 1, callback), else: :ok

      {:error, reason} ->
        IO.puts("Error syncing #{url} (page #{page}): #{inspect(reason)}")
        :ok
    end
  end

  defp sync_all_highlights_paginated(page) do
    IO.puts("Syncing page #{page}")
    url = "https://readwise.io/api/v2/highlights/?page=#{page}&page_size=100"

    case make_request(url) do
      {:ok, %{"results" => results, "next" => next}} ->
        results
        |> Enum.each(&maybe_insert_highlight/1)

        if next do
          sync_all_highlights_paginated(page + 1)
        else
          :ok
        end

      {:error, reason} ->
        IO.puts("Failed to fetch page #{page}: #{inspect(reason)}")
        :ok
    end
  end

  @spec sync_new_highlights() :: :ok
  def sync_new_highlights do
    paginate_api("https://readwise.io/api/v2/highlights", 1, &maybe_insert_highlight/1)
  end

  defp maybe_insert_highlight(%{"id" => id} = data) do
    unless Repo.exists?(from h in Highlight, where: h.readwise_id == ^id) do
      sanitized =
        %Highlight{text: data["text"]}
        |> sanitize_highlight_text()

      %Highlight{}
      |> Highlight.changeset(%{
        readwise_id: id,
        text: sanitized.text,
        note: data["note"],
        location: to_string(data["location"]),
        location_type: data["location_type"],
        highlighted_at: parse_optional_datetime(data["highlighted_at"]),
        url: data["url"],
        color: data["color"],
        updated: data["updated"],
        readwise_book_id: data["book_id"],
        slug: Armitage.Highlight.generate_unique_slug(data["text"])
      })
      |> Repo.insert()
      |> case do
        {:ok, highlight} ->
          IO.puts("Inserted new highlight - id: #{highlight.id}")
          {:ok, highlight}

        {:error, reason} ->
          IO.puts("Failed to insert highlight #{id}: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @spec sync_new_books() :: :ok
  def sync_new_books do
    paginate_api("https://readwise.io/api/v2/books", 1, &maybe_insert_book/1)
  end

  # This is a spechal case wehre if there are no highlights, then we dont want to add this book.
  defp maybe_insert_book(%{"id" => id, "num_highlights" => 0}) do
    IO.puts("Skipping book #{id} (no highlights)")
    {:skip, :no_highlights}
  end

  defp maybe_insert_book(%{"id" => id} = book) do
    case Repo.get_by(Book, readwise_book_id: id) do
      nil ->
        sanitized = sanitize_book_details(book)

        %Book{}
        |> Book.changeset(%{
          readwise_book_id: id,
          title: sanitized["title"],
          author: sanitized["author"],
          url: sanitized["source_url"],
          category: sanitized["category"],
          source: sanitized["source"]
        })
        |> Repo.insert()
        |> case do
          {:ok, book} ->
            IO.puts("Inserted new book - id: #{book.id}")
            {:ok, book}
          {:error, reason} ->
            IO.puts("Failed to insert book #{id}: #{inspect(reason)}")
            {:error, reason}
        end

      existing ->
        {:ok, existing}
    end
  end

  defp cache_highlight(highlight), do: maybe_insert_highlight(highlight)

  defp parse_optional_datetime(nil), do: nil
  defp parse_optional_datetime(datetime) do
    case NaiveDateTime.from_iso8601(datetime) do
      {:ok, naive_dt} -> naive_dt
      _ -> nil
    end
  end


  @spec backfill_books_and_link_highlights() :: :ok
  def backfill_books_and_link_highlights do
    Highlight
    |> select([h], h.readwise_book_id)
    |> where([h], not is_nil(h.readwise_book_id))
    |> distinct(true)
    |> Repo.all()
    |> Enum.each(fn readwise_book_id ->
        case fetch_book_info_by_id(readwise_book_id) do
          {:ok, raw_book} ->
            case maybe_insert_book(raw_book) do
              {:ok, book} ->
                from(h in Highlight, where: h.readwise_book_id == ^readwise_book_id)
                |> Repo.update_all(set: [book_id: book.id])

              {:error, changeset} ->
                IO.puts("Failed to insert book #{readwise_book_id}")
                IO.inspect(changeset.errors)
            end

          {:error, reason} ->
            IO.puts("Failed to fetch book #{readwise_book_id}: #{inspect(reason)}")
        end
      end)

      :ok
    end

  @spec get_books_by_category(String.t()) :: {:ok, list(Book.t())}
  def get_books_by_category(category) do
    books =
      from(b in Book,
        where: b.category == ^category,
        order_by: b.title
      )
      |> Repo.all()

    {:ok, books}
  end

  @spec get_all_books() :: {:ok, list(Book.t())}
  def get_all_books, do: get_books_by_category("books")

  @spec get_all_articles() :: {:ok, list(Book.t())}
  def get_all_articles, do: get_books_by_category("articles")


  @doc """
  Sanitize the highlights that are stored in the database to remove a bunch of things.
  """
  def sanitize_stored_highlights do
    Repo.transaction(fn ->
      Repo.all(Highlight)
      |> Enum.each(fn highlight ->
        sanitized = sanitize_highlight_text(highlight)
        IO.puts("Old text: #{highlight.text}")
        IO.puts("New text: #{sanitized.text}")
        if sanitized.text != highlight.text do
          IO.puts("Updating highlight #{highlight.id}")
          highlight
          |> Ecto.Changeset.change(%{text: sanitized.text})
          |> Repo.update!()
        end
      end)
    end)

    :ok
  end


end
