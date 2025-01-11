import Armitage.ReadWise, only: [get_random_highlight: 0]

defmodule ArmitageWeb.HighlightController do
  use ArmitageWeb, :controller

  def index(conn, _params) do
    # here is where I will need to call the ReadWise API to get a random highlight, and then render it
    # for now, I will just have a dummy highlight to display.
    # Now lets change this so that it calls a function in our code that talks to ReadWise instead
    case get_random_highlight() do
      {:ok, highlight} ->
        # Render the highlight if successful
        render(conn, :index, highlight: highlight)

      {:error, error} ->
        # Handle error gracefully and render an error message
        conn
        |> put_flash(:error, "Failed to fetch highlight: #{inspect(error)}")
        |> render(:index, highlight: nil)
    end
  end
end
