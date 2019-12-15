# frozen_string_literal: true

gem "launchy"

module Minitest
  class Test
    teardown do
      next unless Capybara.current_driver == Capybara.javascript_driver

      return unless failures.any?

      save_and_open_screenshot # rubocop:disable Lint/Debugger
    end
  end
end
