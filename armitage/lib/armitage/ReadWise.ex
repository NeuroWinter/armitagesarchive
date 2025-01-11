defmodule Armitage.ReadWise do
  require Req

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

  # Fetch a paginated list of highlights
  @spec get_highlights() :: {:ok, highlights_response()} | {:error, any()}
  def get_highlights() do
    url = "https://readwise.io/api/v2/highlights/"
    make_request(url)
  end

  # Fetch the total number of highlights
  @spec get_total_highlights() :: {:ok, integer()} | {:error, any()}
  def get_total_highlights() do
    case get_highlights() do
      {:ok, %{"count" => count}} -> {:ok, count}
      {:error, error} -> {:error, error}
    end
  end

  # Fetch a specific highlight by its ID
  @spec get_highlight_by_id(integer()) :: {:ok, highlight()} | {:error, any()}
  def get_highlight_by_id(id) do
    url = "https://readwise.io/api/v2/highlights/#{id}/"
    make_request(url)
  end

  # Fetch a random highlight
  @spec get_random_highlight() :: {:ok, highlight()} | {:error, any()}
  def get_random_highlight() do
    case get_total_highlights() do
      {:ok, total} when total > 0 ->
        # Calculate the total number of pages (page_size = 1 means total = total_pages)
        random_page = Enum.random(1..total)
        fetch_highlight_by_page(random_page)
        # now we need to get the book info for this highlight
        |> case do
          {:ok, %{"book_id" => book_id} = highlight} ->
            case fetch_book_info_by_id(book_id) do
              {:ok, book} ->
                merged_highlight = Map.merge(highlight, sanitize_book_details(book))
                sanitized_highlight = sanitize_highlight_text(merged_highlight)
                {:ok, sanitized_highlight}
              {:error, error} -> {:error, error}
            end
          {:ok, _} -> {:error, "Unexpected response structure"}
          {:error, error} -> {:error, error}
        end
        # Now create a new map that has all of the info including the book deatails in in.

      {:ok, _} ->
        {:error, "No highlights available"}

      {:error, error} ->
        {:error, error}
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
    disallowed_hosts = ["readwise.com", "localhost"]

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

  @spec sanitize_highlight_text(map()) :: map()
  def sanitize_highlight_text(%{"text" => text} = highlight) when is_binary(text) do
    updated_text = text
    |> convert_markdown_links()
    |> remove_bad_references()
    Map.put(highlight, "text", updated_text)
  end

  def sanitize_highlight_text(highlight), do: highlight

  @spec convert_markdown_links(String.t()) :: String.t()
  defp convert_markdown_links(text) do
    regex = ~r/\[([^\]]+)\]\((https?:\/\/[^\)]+)\)/
      Regex.replace(regex, text, fn _, link_text, url ->
        "<a href=\"#{url}\">#{link_text}</a>"
      end)
  end

  @spec remove_bad_references(String.t()) :: String.t()
  defp remove_bad_references(text) do
    regex = ~r/\[\d\]\((private:\/\/|https:\/\/|http:\/\/).*\)/
    Regex.replace(regex, text, "")
  end

  @spec fetch_highlight_by_page(integer()) :: {:ok, highlight()} | {:error, any()}
  defp fetch_highlight_by_page(page) do
    url = "https://readwise.io/api/v2/highlights/?page=#{page}&page_size=1"

    case make_request(url) do
      {:ok, %{"results" => [highlight]}} -> {:ok, highlight}
      {:ok, %{"results" => []}} -> {:error, "No highlights found on the specified page"}
      {:ok, _} -> {:error, "Unexpected response structure"}
      {:error, error} -> {:error, error}
    end
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


  # Generic helper for making HTTP requests
  @spec make_request(String.t()) :: {:ok, map()} | {:error, any()}
  defp make_request(url) do
    Req.get(url,
      headers: [{"Authorization", "Token #{get_access_token()}"}]
    )
    |> case do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "Request failed with status: #{status}"}
      {:error, error} -> {:error, "Request error: #{inspect(error)}"}
    end
  end
end

