defmodule ArmitageWeb.Router do
  use ArmitageWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArmitageWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ArmitageWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/highlights", HighlightController, :index
    get "/books", BookController, :index
    get "/articles", ArticleController, :index
    # Wow these need to come first.
    # So the ordering of this matters. It will match the first one that
    # mateches I guess.
    get "/articles/:article_slug/:highlight_slug", ArticleController, :show_from_article
    get "/articles/:slug", ArticleController, :show
    get "/books/:book_slug/:highlight_slug", BookController, :show_from_book
    get "/books/:slug", BookController, :show
    get "/readwise", ReadwiseController, :index
    get "/colophon", PageController, :colophon
    get "/sitemap.xml", SiteController, :sitemap
    get "/robots.txt", SiteController, :robots
    get "/secure-fonts/:file", FontController, :serve
  end

  # Other scopes may use custom stacks.
  # scope "/api", ArmitageWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:armitage, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ArmitageWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
