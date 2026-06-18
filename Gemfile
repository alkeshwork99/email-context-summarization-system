source "https://rubygems.org"

gem "rails", "~> 8.1.3"

# Database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# Authentication
gem "bcrypt"
gem "jwt"

# Cache
gem "redis"

# HTTP Client (Gemini API)
gem "faraday"

# Observability
gem "opentelemetry-sdk"
gem "opentelemetry-instrumentation-rack"

# CORS
gem "rack-cors"

# Environment variables
gem "dotenv-rails", groups: [ :development, :test ]

# Rails 8 defaults
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Boot optimization
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false

# HTTP caching/compression
gem "thruster", require: false

# Active Storage variants
gem "image_processing", "~> 2.0"

# Windows timezone support
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"

  gem "faker"
end
