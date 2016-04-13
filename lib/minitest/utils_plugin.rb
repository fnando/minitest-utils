require "minitest/utils/reporter"
require "minitest/utils/test_notifier_reporter"

module Minitest
  def self.plugin_utils_init(options)
    reporters = Minitest.reporter.reporters
    reporters.clear
    reporters << Minitest::Utils::Reporter.new(options[:io], options)
    reporters << Minitest::Utils::TestNotifierReporter.new(options[:io], options) if defined?(TestNotifier)
  end
end
