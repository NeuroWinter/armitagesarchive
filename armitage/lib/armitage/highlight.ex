defmodule Armitage.Highlight do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Jason.Encoder
  schema "highlights" do
    field :readwise_id, :integer
    field :text, :string
    field :note, :string
    field :location, :string
    field :location_type, :string
    field :highlighted_at, :utc_datetime
    field :url, :string
    field :color, :string
    field :updated, :string
    field :book_id, :integer
    field :book_title, :string
    field :book_author, :string

    belongs_to :book_ref, Armitage.Book

    timestamps()
  end

  def changeset(highlight, attrs) do
    highlight
    |> cast(attrs, [
      :readwise_id,
      :text,
      :note,
      :location,
      :location_type,
      :highlighted_at,
      :url,
      :color,
      :updated,
      :book_id,
      :book_title,
      :book_author
    ])
    |> validate_required([:readwise_id, :text])
    |> unique_constraint(:readwise_id)
  end
end
