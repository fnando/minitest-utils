module ActiveSupport
  class TestCase
    setup do
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
    end
  end
end
