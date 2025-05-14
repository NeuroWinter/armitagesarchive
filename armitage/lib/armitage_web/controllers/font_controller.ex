defmodule ArmitageWeb.FontController do
  @moduledoc """
  This module is here to ensure that the fonts that we use are protected from other users.
  As per our license for thest fonts, they are not allowed to be acessable or useable from other sites.
  """
  use ArmitageWeb, :controller

  def serve(conn, %{"file" => file}) do
    referer = get_req_header(conn, "referer")
    |> List.first()

    cond do
      String.ends_with?(file, ".woff2") == false ->
        # TODO: change this to a forbidden error
        send_resp(conn, 403, "Forbidden")

      # This is pretty easy to bypass I think, you just need to have a referer that matches here.
      not valid_referer?(referer) ->
        # TODO: change this to a forbidden error
        send_resp(conn, 403, "Forbidden")

      true ->
        path = Path.join(:code.priv_dir(:armitage), "fonts/#{file}")

        if File.exists?(path) do
          conn
          |> put_resp_content_type("font/woff2")
          |> send_file(200, path)
        else
          # TODO Raise proper error here.
          send_resp(conn, 403, "Forbidden")
        end
    end
  end

  defp valid_referer?(nil), do: false

  defp valid_referer?(referer) do
    String.contains?(referer, "armitagesarchive.com") or
    String.contains?(referer, "localhost:4000")
  end


end
