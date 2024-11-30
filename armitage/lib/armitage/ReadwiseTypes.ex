defmodule ReadWiseHighlight do
  # here is where I want to store all the types that can be returned in the readwise api.
  # frist we need to define the struct
  defstruct id: nil,
            text: nil,
            note: nil,
            location: nil,
            location_type: nil,
            highlighted_at: nil,
            url: nil,
            color: nil,
            updated: nil,
            book_id: nil,
            tags: nil
  @type t :: %__MODULE__{
    id: integer,
    text: String.t,
    note: String.t,
    location: integer,
    location_type: String.t,
    highlighted_at: String.t,
    url: String.t,
    color: String.t,
    updated: String.t,
    book_id: integer,
    tags: list(String.t)
  }
end
