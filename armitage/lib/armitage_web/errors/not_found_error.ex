defmodule ArmitageWeb.NotFoundError do
  @moduledoc """
  Raised when a resource is not found, returning a 404 status.
  """

  defexception plug_status: 404, message: "Not found"
end
