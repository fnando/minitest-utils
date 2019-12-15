# frozen_string_literal: true

module Minitest
  module Utils
    module Locale
      class << self
        attr_accessor :setup
        attr_accessor :teardown
      end

      self.setup = proc do
        Rails.application.routes.default_url_options[:locale] = I18n.locale
      end

      self.teardown = proc do
        Rails.application.routes.default_url_options.delete(:locale)
      end

      def self.included(base)
        base.setup do
          instance_eval(&Minitest::Utils::Locale.setup)
        end

        base.teardown do
          instance_eval(&Minitest::Utils::Locale.teardown)
        end
      end
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Minitest::Utils::UrlHelpers
    include Minitest::Utils::Locale
  end
end

module ActionController
  class TestCase
    include Minitest::Utils::UrlHelpers
    include Minitest::Utils::Locale
  end
end

module ActionMailer
  class TestCase
    include Minitest::Utils::UrlHelpers
    include Minitest::Utils::Locale
  end
end
