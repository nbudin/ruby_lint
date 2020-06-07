# frozen_string_literal: true

# Require this file to load code that supports testing using RSpec.

require_relative 'rule_helper'
require_relative 'host_environment_simulation_helper'
require_relative 'shared_contexts'
require_relative 'expect_offense'

RSpec.configure do |config|
  config.include RuleHelper
  config.include HostEnvironmentSimulatorHelper
end
