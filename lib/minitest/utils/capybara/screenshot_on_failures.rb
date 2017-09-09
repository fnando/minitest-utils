gem "launchy"

module Minitest
  class Test
    teardown do
      next unless Capybara.current_driver == Capybara.javascript_driver
      save_and_open_screenshot if failures.any?
    end
  end
end
