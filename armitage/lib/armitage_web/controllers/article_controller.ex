import Armitage.ReadWise, only: [get_all_articles: 0]

defmodule ArmitageWeb.ArticleController do
  use ArmitageWeb, :controller
  alias Armitage.{Repo, Book}
  def index(conn, _params) do
    # Lets change this to use the readwise module.
    case get_all_articles() do
      {:ok, articles} ->
        # Render the articles if successful
        render(conn, :index, articles: articles)
      {:error, error} ->
        # Handle error gracefully and render an error message
        conn
        |> put_flash(:error, "Failed to fetch articles: #{inspect(error)}")
        |> render(:index, articles: [])
    end
  end

  def show(conn, %{"slug" => slug}) do
    article =
      Repo.get_by!(Book, slug: slug)
      |> Repo.preload(:highlights)

    render(conn, "show.html", article: article)
  end

end
