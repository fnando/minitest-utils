# frozen_string_literal: true

module Minitest
  module Utils
    class TestNotifierReporter < Minitest::StatisticsReporter
      def report
        super

        stats = TestNotifier::Stats.new(:minitest,
                                        count: count,
                                        assertions: assertions,
                                        failures: failures,
                                        errors: errors)

        TestNotifier.notify(status: stats.status, message: stats.message)
      end
    end
  end
end
