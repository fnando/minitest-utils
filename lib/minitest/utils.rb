# frozen_string_literal: true

module Minitest
  class << self
    attr_accessor :options
  end

  self.options = {}

  module Utils
    require "minitest"
    require "pathname"
    require_relative "utils/version"
    require_relative "utils/reporter"
    require_relative "utils/extension"
    require_relative "utils/test_notifier_reporter"

    COLOR = {
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      gray: 37
    }.freeze

    def self.color(string, color = :default)
      if color_enabled?
        color = COLOR.fetch(color, 0)
        "\e[#{color}m#{string}\e[0m"
      else
        string
      end
    end

    def self.color_enabled?
      !ENV["NO_COLOR"] && !Minitest.options[:no_color]
    end
  end
end
