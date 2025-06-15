defmodule ArmitageWeb.ArticleController do
  use ArmitageWeb, :controller

  import ArmitageWeb.MetaHelpers, only: [assign_meta: 2, truncate_description: 1]
  import Armitage.ReadWise, only: [get_all_articles: 0]
  import ArmitageWeb.CoreComponents
  alias ArmitageWeb.Router.Helpers, as: Routes
  alias Armitage.{Repo, Book, Highlight}
  alias ArmitageWeb.NotFoundError

  def index(conn, _params) do
    case get_all_articles() do
      {:ok, articles} ->
        conn
        |> assign_meta(
          meta_title: "All Articles",
          meta_description: truncate_description("A collection of saved web articles and their highlights."),
          meta_url: url(~p"/articles"),
          meta_structured_data: [
            %{
              "@context" => "https://schema.org",
              "@type" => "BreadcrumbList",
              "itemListElement" => [
                %{
                  "@type" => "ListItem",
                  "position" => 1,
                  "name" => "Articles",
                  "item" => url(~p"/articles")
                }
              ]
            }
          ]
        )
        |> render(:index, articles: articles)

      {:error, error} ->
        conn
        |> put_flash(:error, "Failed to fetch articles: #{inspect(error)}")
        |> assign_meta(
          meta_title: "All Articles",
          meta_description: "A collection of saved web articles and their highlights.",
          meta_url: url(~p"/articles"),
          meta_structured_data: [
            %{
              "@context" => "https://schema.org",
              "@type" => "BreadcrumbList",
              "itemListElement" => [
                %{
                  "@type" => "ListItem",
                  "position" => 1,
                  "name" => "Articles",
                  "item" => url(~p"/articles")
                }
              ]
            }
          ]
        )
        |> render(:index, articles: [])
    end
  end

  def show(conn, %{"slug" => slug}) do
    article =
      Repo.get_by(Book, slug: slug, category: "articles") ||
        raise NotFoundError, message: "Article not found"

    article = Repo.preload(article, :highlights)

    conn
    |> assign_meta(
      meta_title: "#{article.title}",
      meta_description: truncate_description("Highlights and excerpts from the article: #{article.title}."),
      meta_url: url(~p"/articles/#{article.slug}"),
      meta_structured_data: [
        %{
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
        },
        %{
          "@context" => "https://schema.org",
          "@type" => "BreadcrumbList",
          "itemListElement" => [
            %{
              "@type" => "ListItem",
              "position" => 1,
              "name" => "Articles",
              "item" => url(~p"/articles")
            },
            %{
              "@type" => "ListItem",
              "position" => 2,
              "name" => article.title,
              "item" => url(~p"/articles/#{article.slug}")
            }
          ]
        }
      ]
      |> Enum.map(fn map ->
        map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
      end)
    )
    |> render(:show, article: article)

  end

  def show_from_article(conn, %{"article_slug" => article_slug, "highlight_slug" => highlight_slug}) do
     article =
      Repo.get_by(Book, slug: article_slug, category: "articles") ||
        raise NotFoundError, message: "Article not found"

    highlight =
      Repo.get_by(Ecto.assoc(article, :highlights), slug: highlight_slug) ||
        raise NotFoundError, message: "Highlight not found"

    conn
    |> assign_meta(
      meta_title: "Highlight from #{article.title}",
      meta_description: truncate_description(highlight.text),
      meta_url: url(~p"/articles/#{article.slug}/#{highlight.slug}"),
      meta_image: ArmitageWeb.Endpoint.url() <> "/og/quotes/png/#{highlight.slug}.png",
      meta_structured_data: [
        %{
          "@context" => "https://schema.org",
          "@type" => "Article",
          "headline" => "Highlight from #{article.title}",
          "url" => url(~p"/articles/#{article.slug}/#{highlight.slug}"),
          "mainEntityOfPage" => url(~p"/articles/#{article.slug}/#{highlight.slug}"),
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
        },
        %{
          "@context" => "https://schema.org",
          "@type" => "BreadcrumbList",
          "itemListElement" => [
            %{
              "@type" => "ListItem",
              "position" => 1,
              "name" => "Articles",
              "item" => url(~p"/articles")
            },
            %{
              "@type" => "ListItem",
              "position" => 2,
              "name" => article.title,
              "item" => url(~p"/articles/#{article.slug}")
            },
            %{
              "@type" => "ListItem",
              "position" => 3,
              "name" => "Highlight",
              "item" => url(~p"/articles/#{article.slug}/#{highlight.slug}")
            }
          ]
        }
      ]
      |> Enum.map(fn map -> Enum.reject(map, fn {_k, v} -> is_nil(v) end) |> Map.new() end)
    )
    |> render(:highlight, article: article, highlight: highlight)
  end

end
