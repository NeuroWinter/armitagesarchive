defmodule ArmitageWeb.OGHTML do
  use Phoenix.Template,
    root: "lib/armitage_web/controllers/og_html/",
    pattern: "**/*",
    namespace: ArmitageWeb

  import Phoenix.Template
  embed_templates "og_html/*"
end
