require 'capybara/rails'

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def self.use_javascript!
    setup do
      Capybara.current_driver = Capybara.javascript_driver
    end
  end
end
