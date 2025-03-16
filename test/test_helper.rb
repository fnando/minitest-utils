# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "_test.rb"
end

require "bundler/setup"
require "minitest/utils"
require "minitest/autorun" unless ENV["MT_RUNNER"]

class Test < Minitest::Test
  setup { ENV.delete("MT_RUN_SLOW_TESTS") }
  setup { ENV.delete("MT_TEST_COMMAND") }
end
