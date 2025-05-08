defmodule ArmitageWeb.MetaHelpers do
  import Plug.Conn

  @doc """
  Assigns dynamic meta tags to the conn.
  """
  @spec assign_meta(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def assign_meta(conn, meta_opts) when is_list(meta_opts) do
    Enum.reduce(meta_opts, conn, fn {key, value}, acc ->
      assign(acc, key, value)
    end)
  end

  def truncate_description(nil), do: nil

  @doc """
  Truncates a description to a maximum of 160 characters.
  If the description is longer than 160 characters, it will be truncated and "..." will be appended.
  """
  @spec truncate_description(String.t()) :: String.t()
  def truncate_description(desc) when is_binary(desc) do
    clean = String.trim(desc)
    cond do
      String.length(clean) > 160 ->
        String.slice(clean, 0, 157) <> "..."
      String.length(clean) < 50 ->
        clean <> " Explore more highlights and context at Armitage Archive."
      true ->
        clean
    end
  end

end

