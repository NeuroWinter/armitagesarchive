import Armitage.ReadWise, only: [get_random_highlight: 0]

defmodule ArmitageWeb.HighlightController do
  use ArmitageWeb, :controller

  def index(conn, _params) do
    # here is where I will need to call the ReadWise API to get a random highlight, and then render it
    # for now, I will just have a dummy highlight to display.
    # Now lets change this so that it calls a function in our code that talks to ReadWise instead
    highlight = get_random_highlight()
    render(conn, :index, highlight: highlight)

  end
end
