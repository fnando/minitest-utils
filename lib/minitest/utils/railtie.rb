require "rails/railtie"

module Minitest
  module Utils
    class Railtie < ::Rails::Railtie
      config.after_initialize do
        require "minitest/utils/rails"
      end
    end
  end
end
