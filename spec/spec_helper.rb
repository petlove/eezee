# frozen_string_literal: true

require 'bundler/setup'
require 'support/configs/simple_cov_config'
require 'support/configs/vcr_config'
require 'support/configs/factory_bot_config'
require 'support/shared/eezee/client/builder'
require 'support/shared/eezee/client/requester/get'
require 'support/shared/eezee/client/requester/post'
require 'support/shared/eezee/client/requester/patch'
require 'support/shared/eezee/client/requester/put'
require 'support/shared/eezee/client/requester/delete'
require 'simplecov-cobertura'
require 'simplecov_json_formatter'
require 'pry'

SimpleCovConfig.configure
VCRConfig.configure

require 'eezee'

SimpleCov.start do
  enable_coverage :branch
end

SimpleCov.formatters = [
  SimpleCov::Formatter::Console,
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::CoberturaFormatter
]

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  FactoryBotConfig.configure(config)
end
