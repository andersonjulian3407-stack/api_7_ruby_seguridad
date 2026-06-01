source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "activerecord-sqlserver-adapter"
gem "tiny_tds"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"
gem "rack-cors"
gem "dotenv-rails"

# Módulo 5: JWT y hashing de contraseñas
gem "jwt"           # JSON Web Tokens — firma y verificación con HS256
gem "bcrypt"        # Hashing seguro de contraseñas (uses by has_secure_password)

# Módulo 4: Pruebas
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec"              # Ejecutable bundle exec rspec
  gem "rspec-rails"        # Framework de pruebas
  gem "factory_bot_rails"  # Factories para datos de prueba
  gem "faker"              # Datos falsos para tests
end

group :test do
  gem "shoulda-matchers"   # Matchers adicionales para RSpec
  gem "database_cleaner-active_record"  # Limpieza de BD entre tests
end
