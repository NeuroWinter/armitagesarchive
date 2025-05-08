defmodule ArmitageWeb.ArticleController do
  use ArmitageWeb, :controller

  import ArmitageWeb.MetaHelpers, only: [assign_meta: 2]
  import Armitage.ReadWise, only: [get_all_articles: 0]
  alias ArmitageWeb.Router.Helpers, as: Routes
  alias Armitage.{Repo, Book}

  def index(conn, _params) do
    case get_all_articles() do
      {:ok, articles} ->
        conn
        |> assign_meta(
          meta_title: "All Articles – Armitage Archive",
          meta_description: "A collection of saved web articles and their highlights.",
          meta_url: url(~p"/articles")
        )
        |> render(:index, articles: articles)

      {:error, error} ->
        conn
        |> put_flash(:error, "Failed to fetch articles: #{inspect(error)}")
        |> assign_meta(
          meta_title: "All Articles – Armitage Archive",
          meta_description: "A collection of saved web articles and their highlights.",
          meta_url: url(~p"/articles"),
        )
        |> render(:index, articles: [])
    end
  end
  def show(conn, %{"slug" => slug}) do
    article =
      Repo.get_by!(Book, slug: slug)
      |> Repo.preload(:highlights)

    conn
    |> assign_meta(
      meta_title: "#{article.title} – Armitage Archive",
      meta_description: "Highlights and excerpts from the article: #{article.title}.",
      meta_url: url(~p"/articles/#{article.slug}"),
      meta_structured_data: %{
        "@context" => "https://schema.org",
        "@type" => "Article",
        "headline" => article.title,
        "url" => url(~p"/articles/#{article.slug}"),
        "mainEntityOfPage" => url(~p"/articles/#{article.slug}"),
        "datePublished" =>
          case DateTime.from_naive(article.inserted_at, "Etc/UTC") do
            {:ok, dt} -> DateTime.to_iso8601(dt)
            _ -> nil
          end,
        "author" =>
          if article.author && article.author != "Unknown" do
            %{"@type" => "Person", "name" => article.author}
          else
            nil
          end,
        "publisher" => %{
          "@type" => "Organization",
          "name" => "Armitage Archive",
          "url" => "https://armitagesarchive.com",
          "sameAs" => ArmitageWeb.Meta.Social.links(),
          "logo" => %{
            "@type" => "ImageObject",
            "url" => "https://armitagesarchive.com/og-image.png"
          }
        }
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
    )
    |> render(:show, article: article)
  end
end
