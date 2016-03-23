module Minitest
  module Utils
    require "minitest"
    require "minitest/utils/version"
    require "minitest/utils/reporter"
    require "minitest/utils/extension"
    require "minitest/utils/test_notifier_reporter"

    require "mocha/mini_test" if defined?(Mocha)
  end
end
