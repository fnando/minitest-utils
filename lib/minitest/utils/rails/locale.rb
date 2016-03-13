module ActionDispatch
  class IntegrationTest
    include Minitest::Utils::UrlHelpers

    setup do
      Rails.application.routes.default_url_options[:locale] = I18n.locale
    end
  end
end

module ActionController
  class TestCase
    include Minitest::Utils::UrlHelpers

    setup do
      Rails.application.routes.default_url_options[:locale] = I18n.locale
    end
  end
end

module ActionMailer
  class TestCase
    include Minitest::Utils::UrlHelpers

    setup do
      Rails.application.routes.default_url_options[:locale] = I18n.locale
    end
  end
end
