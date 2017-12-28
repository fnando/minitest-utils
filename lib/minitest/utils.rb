module Minitest
  module Utils
    require "minitest"
    require "minitest/utils/version"
    require "minitest/utils/reporter"
    require "minitest/utils/extension"
    require "minitest/utils/test_notifier_reporter"

    load_lib = lambda do |path, &block|
      begin
        require path
        block.call if block
      rescue LoadError
        return
      end
    end

    load_lib.call "mocha/mini_test"
    load_lib.call "capybara"

    load_lib.call "webmock" do
      require "minitest/utils/setup/webmock"
    end

    load_lib.call "database_cleaner" do
      require "minitest/utils/setup/database_cleaner"
    end

    load_lib.call "factory_bot" do
      require "minitest/utils/setup/factory_bot"
    end

    require "minitest/utils/railtie" if defined?(Rails)
  end
end
