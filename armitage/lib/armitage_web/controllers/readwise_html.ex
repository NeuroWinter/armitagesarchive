defmodule ArmitageWeb.ReadwiseHTML do
  @moduledoc """
  This module contains pages rendered by ReadwiseController.

  See the `readwise_html` directory for all templates available.
  """
  use ArmitageWeb, :html

  embed_templates "readwise_html/*"
end

