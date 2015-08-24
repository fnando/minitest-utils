class ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.default_url_options[:locale] = I18n.locale
    Rails.configuration.action_mailer.default_url_options = Rails.application.routes.default_url_options if defined?(ActionMailer)
  end
end
