# frozen_string_literal: true

module Minitest
  module Utils
    module UrlHelpers
      include Rails.application.routes.url_helpers

      def default_url_options
        config = Rails.configuration

        Rails.application.routes.default_url_options ||
          config.action_controller.default_url_options ||
          config.action_mailer.default_url_options ||
          {}
      end
    end
  end
end

module ActiveSupport
  class TestCase
    extend Minitest::Spec::DSL if defined?(Minitest::Spec::DSL)

    require "minitest/utils/rails/capybara" if defined?(Capybara)

    def t(*, **)
      I18n.t(*, **)
    end

    def l(*, **)
      I18n.l(*, **)
    end
  end
end

module ActionController
  class TestCase
    include Minitest::Utils::UrlHelpers
  end
end

module ActionMailer
  class TestCase
    include Minitest::Utils::UrlHelpers
  end
end
