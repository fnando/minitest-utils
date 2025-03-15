# frozen_string_literal: true

module Minitest
  class << self
    attr_accessor :options
  end

  self.options = {}

  module Utils
    require "minitest"
    require "pathname"
    require_relative "utils/version"
    require_relative "utils/reporter"
    require_relative "utils/extension"
    require_relative "utils/test_notifier_reporter"

    COLOR = {
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      gray: 37
    }.freeze

    def self.color(string, color = :default)
      if color_enabled?
        color = COLOR.fetch(color, 0)
        "\e[#{color}m#{string}\e[0m"
      else
        string
      end
    end

    def self.color_enabled?
      !ENV["NO_COLOR"] && !Minitest.options[:no_color]
    end

    load_lib = lambda do |path, &block|
      require path
      block&.call
      true
    rescue LoadError
      false
    end

    load_lib.call "mocha/mini_test" unless load_lib.call "mocha/minitest"

    load_lib.call "capybara"

    load_lib.call "webmock" do
      require_relative "utils/setup/webmock"
    end

    load_lib.call "database_cleaner" do
      require_relative "utils/setup/database_cleaner"
    end

    load_lib.call "factory_girl" do
      require_relative "utils/setup/factory_girl"
    end

    load_lib.call "factory_bot" do
      require_relative "utils/setup/factory_bot"
    end

    require_relative "utils/railtie" if defined?(Rails)
  end
end
