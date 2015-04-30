class ActiveSupport::TestCase
  extend Minitest::Spec::DSL if defined?(Minitest::Spec::DSL)

  require 'minitest/utils/rails/webmock' if defined?(WebMock)
  require 'minitest/utils/rails/capybara' if defined?(Capybara)
  require 'minitest/utils/rails/factory_girl' if defined?(FactoryGirl)

  def t(*args)
    I18n.t(*args)
  end

  def l(*args)
    I18n.l(*args)
  end
end

class ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.configuration.action_mailer.default_url_options
  end
end
