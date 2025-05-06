defmodule Armitage.SlugCheck do
  alias Armitage.{Repo, Book}

  def slug_exists?(slug) do
    !!Repo.get_by(Book, slug: slug)
  end
end
