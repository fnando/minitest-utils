# frozen_string_literal: true

require "capybara/rails"

module ActionDispatch
  class IntegrationTest
    include Capybara::DSL

    setup do
      Capybara.reset_sessions!
      Capybara.use_default_driver
    end

    def self.use_javascript!(raise_on_javascript_errors: true) # rubocop:disable Metrics/MethodLength
      setup do
        Capybara.current_driver = Capybara.javascript_driver
      end

      teardown do
        next if failures.any?
        next unless raise_on_javascript_errors

        errors = page.driver.browser.manage.logs.get(:browser).select do |log|
          log.level == "SEVERE"
        end

        next unless errors.any?

        messages = errors
                   .map(&:message)
                   .map {|message| message[/(\d+:\d+ .*?)$/, 1] }
                   .join("\n")

        raise "JavaScript Errors\n#{messages}"
      end
    end
  end
end
