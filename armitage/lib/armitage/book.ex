defmodule Armitage.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :readwise_book_id, :integer
    field :title, :string
    field :author, :string
    field :url, :string
    field :category, :string
    field :source, :string

    # This is what lets me associate highlights with books.
    has_many :highlights, Armitage.Highlight

    timestamps()
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, [:readwise_book_id, :title, :author, :url, :category, :source])
    |> validate_required([:readwise_book_id])
    |> unique_constraint(:readwise_book_id)
  end
end
