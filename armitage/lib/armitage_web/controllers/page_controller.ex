defmodule ArmitageWeb.PageController do
  use ArmitageWeb, :controller
  import ArmitageWeb.MetaHelpers, only: [assign_meta: 2, truncate_description: 1]
  import Ecto.Query
  alias Armitage.{Repo, Book}
  import ArmitageWeb.CoreComponents


  def home(conn, _params) do
      recent =
        Repo.one(
          from b in Book,
            join: h in assoc(b, :highlights),
            where: not is_nil(b.slug) and b.category in ["books", "articles"],
            distinct: true,
            order_by: [desc: h.highlighted_at],
            limit: 1,
            preload: [highlights: h]
        )

    conn
    |> assign(:recent, recent)
    |> assign_meta(
      meta_title: "Armitage Archive – Quotes & Highlights",
      meta_description: truncate_description("A curated collection of book quotes, article highlights, and ideas saved using Readwise."),
      meta_url: url(~p"/"),
       meta_structured_data: [
        %{
          "@context" => "https://schema.org",
          "@type" => "WebSite",
          "name" => "Armitage Archive",
          "url" => "https://armitagesarchive.com",
          "sameAs" => ArmitageWeb.Meta.Social.links(),
          "publisher" => %{
            "@type" => "Organization",
            "name" => "Armitage Archive",
            "url" => "https://armitagesarchive.com",
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
              "name" => "Home",
              "item" => url(~p"/")
            }
          ]
        }
      ]
      |> Enum.map(fn map ->
        map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
      end)
    )
    |> render(:home)
  end

  def colophon(conn, _params) do
    conn
      |> assign_meta(
        meta_title: "Armitage Archive – Colophon",
        meta_description:
          truncate_description("Site design notes, font choices, tech stack, and project rationale behind Armitage Archive, a digital quote / highlight library built with Elixir."),
        meta_url: url(~p"/colophon"),
        meta_structured_data: [
          %{
            "@context" => "https://schema.org",
            "@type" => "WebPage",
            "name" => "Armitage Archive - Colophon",
            "url" => url(~p"/colophon"),
            "description" => "Site design notes, font choices, tech stack, and project rationale behind Armitage Archive, a digital quote / highlight library built with Elixir.",
            "inLanguage" => "en",
            "about" => "Quotes and highlights library powered by Elixir and Phoenix Framework"
          },
          %{
            "@context" => "https://schema.org",
            "@type" => "BreadcrumbList",
            "itemListElement" => [
              %{
                "@type" => "ListItem",
                "position" => 1,
                "name" => "Home",
                "item" => url(~p"/")
              },
              %{
                "@type" => "ListItem",
                "position" => 2,
                "name" => "Colophon",
                "item" => url(~p"/colophon")
              }
            ]
          }
        ]
        |> Enum.map(fn map ->
          map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
        end)
      )
      |> render(:colophon)
  end

end
