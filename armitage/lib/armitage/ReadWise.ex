defmodule Armitage.ReadWise do
  @moduledoc """
  This is the module that holds all the interactions with the Readwise API.
  """
  require Req
  import Ecto.Query

  alias Armitage.Book
  alias Armitage.Repo
  alias Armitage.Highlight

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
      |> normalize_quotes()
      |> remove_bad_references()
      |> convert_markdown_links()
      |> remove_internal_links()
      |> remove_private_href_links()

    %Armitage.Highlight{highlight | text: updated_text}
  end

  def sanitize_highlight_text(highlight), do: highlight

  # This is to get rid of those annoying links to foot notes and stuff.
  defp remove_internal_links(html) do
    # Remove links like <a href="#rlink123">...</a>
    Regex.replace(~r/<a href="#rlink\d+">(.*?)<\/a>/, html, "\\1", global: true)
  end

  defp normalize_quotes(text) do
    text
    |> String.replace(~r/[“”]/u, "\"")
    |> String.replace(~r/[‘’]/u, "'")
  end


  @spec convert_markdown_links(String.t()) :: String.t()
  defp convert_markdown_links(text) do
    Earmark.as_html!(text)
  end

  @spec remove_bad_references(String.t()) :: String.t()
  defp remove_bad_references(text) do
    regex = ~r/\[\d\]\((private:\/\/|https?:\/\/).*?\)/
    Regex.replace(regex, text, "", global: true)
  end

  defp remove_private_href_links(html) do
    Regex.replace(~r/<a href="private:\/\/[^"]*">(.*?)<\/a>/, html, "\\1", global: true)
  end

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

  defp sync_all_highlights_paginated(page) do
    IO.puts("Syncing page #{page}")
    url = "https://readwise.io/api/v2/highlights/?page=#{page}&page_size=100"

    case make_request(url) do
      {:ok, %{"results" => results, "next" => next}} ->
        results
        |> Enum.each(&cache_highlight/1)

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

  defp cache_highlight(%{"id" => id} = highlight) do
    case Armitage.Repo.get_by(Armitage.Highlight, readwise_id: id) do
      nil ->
        %Armitage.Highlight{}
        |> Armitage.Highlight.changeset(%{
          readwise_id: highlight["id"],
          text: highlight["text"],
          note: highlight["note"],
          location: to_string(highlight["location"]),
          location_type: highlight["location_type"],
          highlighted_at: parse_optional_datetime(highlight["highlighted_at"]),
          url: highlight["url"],
          color: highlight["color"],
          updated: highlight["updated"],
          readwise_book_id: highlight["book_id"]
        })
        |> Armitage.Repo.insert!()

      _ ->
        :ok
    end
  end

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
          sanitized_book = sanitize_book_details(raw_book)

          attrs = %{
            readwise_book_id: readwise_book_id,
            title: sanitized_book["title"],
            author: sanitized_book["author"],
            url: sanitized_book["source_url"],
            category: sanitized_book["category"],
            source: sanitized_book["source"]
          }

          book =
            Repo.get_by(Book, readwise_book_id: readwise_book_id) ||
              Repo.insert!(Book.changeset(%Book{}, attrs))

          from(h in Highlight, where: h.readwise_book_id == ^readwise_book_id)
          |> Repo.update_all(set: [book_id: book.id])

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
