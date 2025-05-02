import Armitage.ReadWise, only: [get_all_books: 0]

defmodule ArmitageWeb.BookController do
  use ArmitageWeb, :controller

  def index(conn, _params) do
    # Lets change this to use the readwise module.
    case get_all_books() do
      {:ok, books} ->
        # Render the books if successful
        render(conn, :index, books: books)
      {:error, error} ->
        # Handle error gracefully and render an error message
        conn
        |> put_flash(:error, "Failed to fetch books: #{inspect(error)}")
        |> render(:index, books: [])
    end
  end
end
