Tracks::Application.configure do
  config.middleware.use 'Rack::Bug',
    :secret_key => '7370ca22d6be47dd8392a54db32a64a9d2cfb030e698e50252a7682da89de2e5aa80488f6bf73d3d8b1cf7939468774382739c56c3d687d326780bdbe53c899f',
    :panel_classes => [
       Rack::Bug::RailsInfoPanel,
       Rack::Bug::TimerPanel,
       Rack::Bug::RequestVariablesPanel,
       Rack::Bug::ActiveRecordPanel,
       Rack::Bug::TemplatesPanel,
       Rack::Bug::LogPanel,
       Rack::Bug::SQLPanel,    # -- adds ~10 sec to load time
       # Rack::Bug::CachePanel,  # -- adds ~10 sec to load time
       Rack::Bug::MemoryPanel
     ]
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
end
