defmodule Armitage.Highlight do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
    field :slug, :string

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
      :book_id,
      :slug
    ])
    |> validate_required([:readwise_id, :text])
    |> unique_constraint(:readwise_id)
    |> unique_constraint(:slug)
  end

  def generate_unique_slug(text) do
    base = generate_slug(text)
    ensure_unique_slug(base)
  end

  def generate_slug(text) do
    base = text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.slice(0, 60)

    base <> short_hash(text)
  end

  defp short_hash(text) do
    :crypto.hash(:sha256, text)
    |> Base.encode16(case: :lower)
    |> binary_part(0, 6)
  end

  defp ensure_unique_slug(base, attempt \\ 0) do
    candidate = if attempt == 0, do: base, else: "#{base}-#{attempt}"

    exists =
      from(h in __MODULE__, where: h.slug == ^candidate)
      |> Armitage.Repo.exists?()

    if exists, do: ensure_unique_slug(base, attempt + 1), else: candidate
  end

end
