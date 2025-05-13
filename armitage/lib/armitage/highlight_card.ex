defmodule Armitage.HighlightCard do
  @moduledoc """
  This module is responsible for generating SVG highlight cards to be converted.
  """

  alias Armitage.{Highlight, Book}
  alias ArmitageWeb.OGView
  import Phoenix.HTML.Engine, only: [strip_tags: 1]


  @output_dir Path.join(:code.priv_dir(:armitage), "static/og/quotes")

  def generate_svg(%Highlight{text: text, slug: slug, book: %Book{title: title, author: author}}) do
    [line1, line2, line3] = split_text(clean_text(text))

    assigns = %{
      line1: line1,
      line2: line2,
      line3: line3,
      title: title,
      author: author
    }

    #svg =
      #Phoenix.Template.render_to_string(
        #ArmitageWeb.OGHTML,
        #"highlight",
        #"html",
        #assigns
      #)
    #svg = ArmitageWeb.OGHTML.highlight(assigns) |> Phoenix.HTML.safe_to_string()
    svg = Phoenix.Template.render_to_string(ArmitageWeb.OGHTML, "highlight", "html", assigns)

    File.mkdir_p!(@output_dir)
    path = Path.join(@output_dir, "#{slug}.svg")
    if not File.exists?(path) or File.read!(path) != svg do
      File.write!(path, svg)
    end
  end

  defp strip_tags(text) do
    Regex.replace(~r/<[^>]*>/, text, "")
  end

  defp clean_text(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.trim()
    |> strip_tags()
  end

  def split_text(text) do
    words = String.split(text)

    {lines, last_line, _len, used_word_count} =
      Enum.reduce(words, {[], "", 0, 0}, fn word, {acc, line, len, count} ->
        word_len = String.length(word)

        if len + word_len + 1 <= 40 do
          {acc, line <> " " <> word, len + word_len + 1, count + 1}
        else
          {[String.trim(line) | acc], word, word_len, count + 1}
        end
      end)

    all_lines = Enum.reverse([String.trim(last_line) | lines])

    {shown_lines, truncated?} =
      if length(all_lines) > 3, do: {Enum.take(all_lines, 3), true}, else: {all_lines, false}

    case shown_lines do
      [a, b, c] -> [a, b, maybe_add_ellipsis(c, truncated?)]
      [a, b] -> [a, maybe_add_ellipsis(b, truncated?), ""]
      [a] -> [maybe_add_ellipsis(a, truncated?), "", ""]
      _ -> ["", "", ""]
    end
  end



  defp maybe_add_ellipsis(line, true), do: String.trim_trailing(line) <> "…"
  defp maybe_add_ellipsis(line, false), do: line

end
