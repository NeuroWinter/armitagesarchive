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

end
