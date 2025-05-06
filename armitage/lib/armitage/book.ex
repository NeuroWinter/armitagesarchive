defmodule Armitage.Book do
  use Ecto.Schema
  import Ecto.Changeset
  alias Armitage.Slug
  alias Armitage.Repo

  schema "books" do
    field :readwise_book_id, :integer
    field :title, :string
    field :author, :string
    field :url, :string
    field :category, :string
    field :source, :string
    field :slug, :string

    # This is what lets me associate highlights with books.
    has_many :highlights, Armitage.Highlight

    timestamps()
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, [:readwise_book_id, :title, :author, :url, :category, :source])
    |> validate_required([:readwise_book_id])
    |> maybe_put_slug()
    |> unique_constraint(:readwise_book_id)
    |> unique_constraint(:slug)
  end

  defp maybe_put_slug(changeset) do
    # If we already have a slug dont do a thing
    if get_field(changeset, :slug) do
      changeset
    else
      category = get_field(changeset, :category)
      title = get_field(changeset, :title) || ""
      author = get_field(changeset, :author) || ""

      case category do
        "books" ->
          put_change(changeset, :slug, Slug.build_book_slug(title, author))
        "articles" ->
          put_change(changeset, :slug, Slug.build_article_slug(title, author))
        _ ->
          changeset
      end
    end
  end

  @doc "Returns true if a book with the given slug exists."
  @spec slug_exists?(String.t()) :: boolean()
  def slug_exists?(slug) do
    !!Repo.get_by(Book, slug: slug)
  end

end
