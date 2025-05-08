defmodule ArmitageWeb.SiteController do
  use ArmitageWeb, :controller
  alias Armitage.{Repo, Book}
  import Ecto.Query, only: [from: 2]

  def sitemap(conn, _params) do
    books = Repo.all(Book)
    books =
      Repo.all(Book)
      |> Enum.filter(fn book -> not is_nil(book.slug) end)
      |> Enum.map(fn book ->
        %{
          loc: url(conn, ~p"/books/#{book.slug}"),
          lastmod: book.updated_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
        }
      end)

    articles =
      Repo.all(from b in Book, where: not is_nil(b.url) and not is_nil(b.slug))
      |> Enum.map(fn article ->
        %{
          loc: url(conn, ~p"/articles/#{article.slug}"),
          lastmod: article.updated_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
        }
      end)

    urls =
      [
        url(conn, ~p"/"),
        url(conn, ~p"/books"),
        url(conn, ~p"/articles"),
        url(conn, ~p"/readwise"),
        url(conn, ~p"/highlights")
      ] ++
        Enum.map(books, & &1.loc) ++
        Enum.map(articles, & &1.loc)

    xml = build_sitemap(urls)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, """
    User-agent: *
    Allow: /

    Sitemap: #{url(conn, ~p"/sitemap.xml")}
    """)
  end

  defp build_sitemap(urls) do
    entries =
      Enum.map(urls, fn url ->
        """
        <url>
          <loc>#{url}</loc>
        </url>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.join(entries, "\n")}
    </urlset>
    """
  end
end

