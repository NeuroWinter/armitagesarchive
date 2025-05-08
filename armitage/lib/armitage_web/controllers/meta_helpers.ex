defmodule ArmitageWeb.MetaHelpers do
  import Plug.Conn

  @doc """
  Assigns dynamic meta tags to the conn.
  """
  def assign_meta(conn, meta_opts) when is_list(meta_opts) do
    Enum.reduce(meta_opts, conn, fn {key, value}, acc ->
      assign(acc, key, value)
    end)
  end
end

