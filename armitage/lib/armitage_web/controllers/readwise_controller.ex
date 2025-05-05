defmodule ArmitageWeb.ReadwiseController do
  use ArmitageWeb, :controller
  import ArmitageWeb.MetaHelpers, only: [assign_meta: 2]


  def index(conn, _params) do
      conn
      |> assign_meta(
        meta_title: "How this site works – Armitage Archive",
        meta_description: "Learn how Armitage Archive uses Readwise and Reader to collect, resurface, and share highlights from books, articles, and newsletters.",
        meta_url: url(~p"/readwise"),
        meta_structured_data:
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
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()
      )
      |> render(:index)
  end
end

