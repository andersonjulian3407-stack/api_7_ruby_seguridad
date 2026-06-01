# spec/rails_helper.rb — Módulo 4: Configuración de pruebas RSpec
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"

require "erb"
ERB.const_set(:ENCODING_FLAG, "#.*coding[:=]\\s*([^\\s;]+)") unless ERB.const_defined?(:ENCODING_FLAG)

require_relative "../config/environment"
require "rspec/rails"

RSpec.configure do |config|
  config.fixture_paths = [ "#{::Rails.root}/spec/fixtures" ]
  config.use_transactional_fixtures = true  # Rollback automático entre tests
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end
