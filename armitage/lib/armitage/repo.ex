defmodule Armitage.Repo do
  use Ecto.Repo,
    otp_app: :armitage,
    adapter: Ecto.Adapters.Postgres
end
