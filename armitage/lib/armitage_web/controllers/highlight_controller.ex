import Armitage.ReadWise, only: [get_random_highlight: 0]
import ArmitageWeb.MetaHelpers, only: [assign_meta: 2]

defmodule ArmitageWeb.HighlightController do
  use ArmitageWeb, :controller

  def index(conn, _params) do
    case get_random_highlight() do
      {:ok, highlight} ->
        conn
        |> assign_meta(
          meta_title: "Random Highlight – Armitage Archive",
          meta_description: "A randomly selected highlight from my reading archive. This was captured using Readwise.",
          meta_url: url(~p"/highlights"),
        )
        |> render(:index, highlight: highlight)

      {:error, error} ->
        conn
        |> put_flash(:error, "Failed to fetch highlight: #{inspect(error)}")
        |> render(:index, highlight: nil)
    end
  end
end
