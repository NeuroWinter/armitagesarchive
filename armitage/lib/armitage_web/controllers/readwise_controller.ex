defmodule ArmitageWeb.ReadwiseController do
  use ArmitageWeb, :controller
  import ArmitageWeb.MetaHelpers, only: [assign_meta: 2, truncate_description: 1]


  def index(conn, _params) do
      conn
      |> assign_meta(
        meta_title: "How this site works – Armitage Archive",
        meta_description: "Learn how Armitage Archive uses Readwise and Reader to collect, resurface, and share highlights from books, articles, and newsletters.",
        meta_url: url(~p"/readwise"),
        meta_structured_data: [
          %{
            "@context" => "https://schema.org",
            "@type" => "WebPage",
            "headline" => "How this site works – Armitage Archive",
            "url" => url(~p"/readwise"),
            "mainEntityOfPage" => url(~p"/readwise"),
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
                "name" => "How this site works",
                "item" => url(~p"/readwise")
              }
            ]
          }
        ]
        |> Enum.map(fn map ->
          map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
        end)
      )
      |> render(:index)
  end
end

