import Config

# Enable the server when PHX_SERVER is set to true in prod
if config_env() == :prod and System.get_env("PHX_SERVER") == "true" do
  config :armitage, ArmitageWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL is missing. Example: ecto://USER:PASS@HOST/DATABASE"

  config :armitage, Armitage.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: false

  readwise_token =
    System.get_env("READWISE_ACCESS_TOKEN") ||
      raise "READWISE_ACCESS_TOKEN is missing."

  config :armitage, :readwise_access_token, readwise_token

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "armitagesarchive.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :armitage, ArmitageWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :armitage, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :phoenix, :url,
    scheme: "https",
    host: "armitagesarchive.com",
    port: 443
end

