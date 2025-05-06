defmodule Armitage.Slug do
  @moduledoc """
  This module provides the utilites to convert articles and books titles,
  authors into url friendly slugs for routes.
  """

  @doc """
  Build a slug for a book using the title and author.
  """
  @spec build_book_slug(String.t(), String.t()) :: String.t()
  def build_book_slug(title, author) do
    [title, author]
    |> Enum.map(&slugify/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("-")
  end

  @doc """
  Build a slug for an article using the title and author.
  If the slug already exists append a hash to the slug.
  """
  @spec build_article_slug(String.t(), String.t() | nil) :: String.t()
  def build_article_slug(title, author \\ nil) do
    base_slug = slugify(title)

    if Armitage.SlugCheck.slug_exists?(base_slug) do
      # If for some chance we already hav this slug in the db.
      # use the author to help deferentiate.
      author_slug = slugify(author || "")
      full_slug = base_slug <> "-" <> author_slug

      if Armitage.SlugCheck.slug_exists?(full_slug) do
        # Well bugger that exists too, use some random hash at the end.
        hash = :crypto.hash(:sha, title <> (author || ""))
               |> Base.encode16(case: :lower)
               |> binary_part(0, 6)

        "#{full_slug}-#{hash}"
      else
        full_slug
      end
    else
      base_slug
    end
  end


  def slugify(nil), do: ""

  @doc """
  Slugify a string by removing accents, punctuation, and whitespace.
  It converts the string to lowercase and replaces spaces with dashes.
  It also un accesnts characters.
  """
  def slugify(string) do
    string
    # convet text to split accented words
    |> String.normalize(:nfd)
    # Remove the accents
    |> String.replace(~r/[\p{Mn}]/u, "")
    |> String.downcase()
    # get rid of any punctuation
    |> String.replace(~r/[^\p{L}0-9\s-]/u, "")
    # Get rid of any white space
    |> String.replace(~r/\s+/, "-")
    # turn multi dashes into a single dash
    |> String.replace(~r/-+/, "-")
    # get rid of any leading or trailing dashes
    |> String.trim("-")
  end
end
