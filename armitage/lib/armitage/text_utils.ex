defmodule Armitage.TextUtils do
  @moduledoc """
  Utility functions for text manipulation and formatting.
  """

  @doc """
  Removes all of the html tags from the passed in string.
  """
  @spec strip_html_tags(String.t()) :: String.t()
  def strip_html_tags(text) do
    Regex.replace(~r/<[^>]*>/, text, "")
  end

  @doc """
  Strip HTML tags and trim surrounding whitespace.
  """
  @spec clean_text(String.t()) :: String.t()
  def clean_text(text) do
    text
    |> strip_html_tags()
    |> String.trim()
  end

  @doc """
  Normalize curly quotes to straight ones.
  """
  @spec normalize_quotes(String.t()) :: String.t()
  def normalize_quotes(text) do
    text
    |> String.replace(~r/[“”]/u, "\"")
    |> String.replace(~r/[‘’]/u, "'")
  end

  @doc """
  Remove markdown-style bad references like `[1](private://…)`.
  """
  @spec remove_bad_references(String.t()) :: String.t()
  def remove_bad_references(text) do
    regex = ~r/\[\d\]\((private:\/\/|https?:\/\/).*?\)/
    Regex.replace(regex, text, "", global: true)
  end

  @doc """
  Convert markdown links to HTML via Earmark.
  """
  @spec convert_markdown_links(String.t()) :: String.t()
  def convert_markdown_links(text), do: Earmark.as_html!(text)

  @doc """
  Strip out internal anchor links like `<a href=\"#rlink123\">…</a>`.
  """
  @spec remove_internal_links(String.t()) :: String.t()
  def remove_internal_links(html) do
    Regex.replace(~r/<a href="#rlink\d+">(.*?)<\/a>/, html, "\\1", global: true)
  end

  def remove_private_href_links(html) do
    Regex.replace(~r/<a href="private:\/\/[^"]*">(.*?)<\/a>/, html, "\\1", global: true)
  end


end
