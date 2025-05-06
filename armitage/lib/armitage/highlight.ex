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
    field :readwise_book_id, :integer

    belongs_to :book, Armitage.Book

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
      :readwise_book_id,
      :book_id
    ])
    |> validate_required([:readwise_id, :text])
    |> unique_constraint(:readwise_id)
  end


end
