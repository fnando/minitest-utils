# frozen_string_literal: true

require_relative "utils/reporter"
require_relative "utils/test_notifier_reporter"

module Minitest
  class << self
    attr_accessor :options
  end

  self.options = {}

  def self.plugin_utils_options(opts, options)
    Minitest.options = options

    opts.on("--slow", "Run slow tests") do
      options[:slow] = true
    end

    opts.on("--hide-slow", "Hide list of slow tests") do
      options[:hide_slow] = true
    end

    opts.on("--slow-threshold=THRESHOLD",
            "Set the slow threshold (in seconds)") do |v|
      options[:slow_threshold] = v.to_f
    end
  end

  def self.plugin_utils_init(options)
    reporters = Minitest.reporter.reporters
    reporters.clear
    reporters << Minitest::Utils::Reporter.new(options[:io], options)

    begin
      require "test_notifier"
      reporters << Minitest::Utils::TestNotifierReporter.new(
        options[:io],
        options
      )
    rescue LoadError
      # noop
    end
  end
end
