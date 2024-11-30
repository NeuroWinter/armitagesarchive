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

      {:ok, _} ->
        {:error, "No highlights available"}

      {:error, error} ->
        {:error, error}
    end
  end

  # Helper to fetch a single highlight from a random page
  @spec fetch_highlight_by_page(integer()) :: {:ok, highlight()} | {:error, any()}
  defp fetch_highlight_by_page(page) do
    url = "https://readwise.io/api/v2/highlights/?page=#{page}&page_size=1"
    case make_request(url) do
      {:ok, %{"results" => [highlight]}} -> {:ok, highlight}
      {:ok, _} -> {:error, "No highlights found on the specified page"}
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

