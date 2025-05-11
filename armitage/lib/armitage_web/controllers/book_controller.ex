import Armitage.ReadWise, only: [get_all_books: 0]
import ArmitageWeb.MetaHelpers, only: [assign_meta: 2, truncate_description: 1]
import ArmitageWeb.CoreComponents


defmodule ArmitageWeb.BookController do
  use ArmitageWeb, :controller
  alias Armitage.{Repo, Book}

  def index(conn, _params) do
    # Lets change this to use the readwise module.
    case get_all_books() do
      {:ok, books} ->
        conn
        |> assign_meta(
          meta_title: "All Books – Armitage Archive",
          meta_description: truncate_description("A collection of books I've highlighted using Readwise."),
          meta_url: url(~p"/books"),
          meta_structured_data: [
            %{
              "@context" => "https://schema.org",
              "@type" => "BreadcrumbList",
              "itemListElement" => [
                %{
                  "@type" => "ListItem",
                  "position" => 1,
                  "name" => "Books",
                  "item" => url(~p"/books")
                }
              ]
            }
          ]
        )
        |> render(:index, books: books)
      {:error, error} ->
        # Handle error gracefully and render an error message
        conn
        |> put_flash(:error, "Failed to fetch books: #{inspect(error)}")
        |> assign_meta(
          meta_title: "All Books – Armitage Archive",
          meta_description: "A collection of books I've highlighted using Readwise.",
          meta_url: url(~p"/books"),
          meta_structured_data: [
            %{
              "@context" => "https://schema.org",
              "@type" => "BreadcrumbList",
              "itemListElement" => [
                %{
                  "@type" => "ListItem",
                  "position" => 1,
                  "name" => "Books",
                  "item" => url(~p"/books")
                }
              ]
            }
          ]
        )
        |> render(:index, books: [])
    end
  end

  def show(conn, %{"slug" => slug}) do
    book =
      Repo.get_by!(Book, slug: slug)
      |> Repo.preload(:highlights)

    conn
    |> assign_meta(
      meta_title: "#{book.title} by #{book.author} – Armitage Archive",
      meta_description: truncate_description(
        "Quotes and highlights from #{book.title} by #{book.author}, saved and highlighted for future reference using Readwise."
      ),
      meta_url: url(~p"/books/#{book.slug}"),
      meta_structured_data: [
        %{
          "@context" => "https://schema.org",
          "@type" => "Book",
          "name" => book.title,
          "mainEntityOfPage" => url(~p"/books/#{book.slug}"),
          "url" => url(~p"/books/#{book.slug}"),
          "datePublished" =>
            case DateTime.from_naive(book.inserted_at, "Etc/UTC") do
              {:ok, dt} -> DateTime.to_iso8601(dt)
              _ -> nil
            end,
          "author" =>
            if book.author && book.author != "Unknown" do
              %{"@type" => "Person", "name" => book.author}
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
              "name" => "Books",
              "item" => url(~p"/books")
            },
            %{
              "@type" => "ListItem",
              "position" => 2,
              "name" => book.title,
              "item" => url(~p"/books/#{book.slug}")
            }
          ]
        }
      ]
      |> Enum.map(fn map ->
        map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
      end)
    )
    |> render("show.html", book: book)
  end


  def show_from_book(conn, %{"book_slug" => book_slug, "highlight_slug" => highlight_slug}) do
    book =
      Repo.get_by!(Book, slug: book_slug, category: "books")

    highlight =
      Repo.get_by!(Ecto.assoc(book, :highlights), slug: highlight_slug)

    conn
    |> assign_meta(
      meta_title: "Highlight from #{book.title} – Armitage Archive",
      meta_description: truncate_description(highlight.text),
      meta_url: url(~p"/books/#{book.slug}/#{highlight.slug}"),
      meta_structured_data: [
        %{
          "@context" => "https://schema.org",
          "@type" => "Book",
          "name" => book.title,
          "url" => url(~p"/books/#{book.slug}/#{highlight.slug}"),
          "mainEntityOfPage" => url(~p"/books/#{book.slug}/#{highlight.slug}"),
          "datePublished" =>
            case DateTime.from_naive(book.inserted_at, "Etc/UTC") do
              {:ok, dt} -> DateTime.to_iso8601(dt)
              _ -> nil
            end,
          "author" =>
            if book.author && book.author != "Unknown" do
              %{"@type" => "Person", "name" => book.author}
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
              "name" => "Books",
              "item" => url(~p"/books")
            },
            %{
              "@type" => "ListItem",
              "position" => 2,
              "name" => book.title,
              "item" => url(~p"/books/#{book.slug}")
            },
            %{
              "@type" => "ListItem",
              "position" => 3,
              "name" => "Highlight",
              "item" => url(~p"/books/#{book.slug}/#{highlight.slug}")
            }
          ]
        }
      ]
      |> Enum.map(fn map ->
        Enum.reject(map, fn {_k, v} -> is_nil(v) end) |> Map.new()
      end)
    )
    |> render("highlight.html", book: book, highlight: highlight)
  end

end
