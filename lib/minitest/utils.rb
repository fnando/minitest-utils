# frozen_string_literal: true

module Minitest
  module Utils
    require "minitest"
    require "pathname"
    require_relative "utils/version"
    require_relative "utils/reporter"
    require_relative "utils/extension"
    require_relative "utils/test_notifier_reporter"

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
