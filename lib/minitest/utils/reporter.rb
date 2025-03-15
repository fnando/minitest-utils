# frozen_string_literal: true

module Minitest
  class Test
    class << self
      attr_accessor :slow_threshold
    end

    def self.inherited(child)
      child.slow_threshold = slow_threshold
      super
    end
  end

  module Utils
    class Reporter < Minitest::StatisticsReporter
      def self.filters
        @filters ||= []
      end

      COLOR_FOR_RESULT_CODE = {
        "." => :green,
        "E" => :red,
        "F" => :red,
        "S" => :yellow
      }.freeze

      COLOR = {
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        gray: 37
      }.freeze

      def initialize(*)
        super
        @color_enabled = io.respond_to?(:tty?) && io.tty?
      end

      def start
        super
        io.puts "Run options: #{options[:args]}\n"
      end

      def record(result)
        super
        print_result_code(result.result_code)
      end

      def report
        super
        io.sync = true if io.respond_to?(:sync)

        failing_results = results.reject(&:skipped?)
        skipped_results = results.select(&:skipped?)

        color = :green
        color = :yellow if skipped_results.any?
        color = :red if failing_results.any?

        print_failing_results(failing_results)
        print_skipped_results(skipped_results, failing_results.size)

        io.print "\n\n"
        io.puts statistics
        io.puts color(summary, color)

        if failing_results.any?
          io.puts "\nFailed Tests:\n"
          failing_results.each {|result| display_replay_command(result) }
          io.puts "\n\n"
        else
          print_slow_results
        end
      end

      def slow_threshold_for(test_case)
        test_case[:slow_threshold] || Minitest.options[:slow_threshold] || 0.1
      end

      def slow_tests
        Test
          .tests
          .values
          .select { _1[:time] }
          .filter { _1[:time] > slow_threshold_for(_1) }
          .sort_by { _1[:time] }
          .reverse
      end

      def print_failing_results(results, initial_index = 1)
        results.each.with_index(initial_index) do |result, index|
          display_failing(result, index)
        end
      end

      def print_skipped_results(results, initial_index)
        results
          .each
          .with_index(initial_index + 1) do |result, index|
          display_skipped(result, index)
        end
      end

      def print_slow_results
        test_results = slow_tests.take(10)

        return if Minitest.options[:hide_slow]
        return unless test_results.any?

        io.puts "\nSlow Tests:\n"

        test_results.each_with_index do |info, index|
          location = info[:source_location].join(":")
          duration = format_duration(info[:time])

          prefix = "#{index + 1}) "
          padding = " " * prefix.size

          io.puts color("#{prefix}#{info[:description]} (#{duration})", :red)
          io.puts color("#{padding}#{location}", :blue)
          io.puts
        end
      end

      def format_duration(duration_in_seconds)
        duration_ns = duration_in_seconds * 1_000_000_000

        number, unit = if duration_ns < 1000
                         [duration_ns, "ns"]
                       elsif duration_ns < 1_000_000
                         [duration_ns / 1000, "μs"]
                       elsif duration_ns < 1_000_000_000
                         [duration_ns / 1_000_000, "ms"]
                       else
                         [duration_ns / 1_000_000_000, "s"]
                       end

        number =
          format("%.2f", number).gsub(/0+$/, "").delete_suffix(".")

        "#{number}#{unit}"
      end

      private def statistics
        format(
          "Finished in %.6fs, %.4f runs/s, %.4f assertions/s.",
          total_time,
          count / total_time,
          assertions / total_time
        )
      end

      private def summary # :nodoc:
        [
          pluralize("run", count),
          pluralize("assertion", assertions),
          pluralize("failure", failures),
          pluralize("error", errors),
          pluralize("skip", skips)
        ].join(", ")
      end

      private def indent(text)
        text.gsub(/^/, "      ")
      end

      private def display_failing(result, index)
        backtrace = backtrace(result.failure.backtrace)
        message = result.failure.message
        message = message.lines.tap(&:pop).join.chomp if result.error?

        test = find_test_info(result)

        output = ["\n\n"]
        output << color(format("%4d) %s", index, test[:description]))
        output << "\n" << color(indent(message), :red)
        output << "\n" << color(backtrace, :blue)
        io.print output.join
      end

      private def display_skipped(result, index)
        location = filter_backtrace(
          result
            .failure
            .backtrace_locations
            .map {|l| [l.path, l.lineno].join(":") }
        ).first

        location, line = location.to_s.split(":")
        location = Pathname(location).relative_path_from(Pathname.pwd)
        location = "#{location}:#{line}"

        test = find_test_info(result)
        output = ["\n\n"]
        output << color(
          format("%4d) %s [SKIPPED]", index, test[:description]), :yellow
        )

        message = "Reason: #{result.failure.message}"
        output << "\n" << indent(color(message, :yellow))
        output << "\n" << indent(color(location, :yellow))

        io.print output.join
      end

      private def display_replay_command(result)
        test = find_test_info(result)
        return if test[:source_location].empty?

        command = build_test_command(test, result)

        output = ["\n"]
        output << color(command, :red)

        io.print output.join
      end

      private def find_test_info(result)
        Test.tests.fetch("#{result.klass}##{result.name}")
      end

      private def backtrace(backtrace)
        backtrace = filter_backtrace(backtrace).map do |line|
          location(line, true)
        end

        return if backtrace.empty?

        indent(backtrace.join("\n")).gsub(/^(\s+)/, "\\1# ")
      end

      private def location(location, include_line_number = false) # rubocop:disable Style/OptionalBooleanParameter
        matches = location.match(/^(<.*?>)/)

        return matches[1] if matches

        regex = include_line_number ? /^([^:]+:\d+)/ : /^([^:]+)/
        path = location[regex, 1]

        return location unless path

        location = File.expand_path(path)

        return location unless location.start_with?(Dir.pwd)

        location.delete_prefix("#{Dir.pwd}/")
      end

      private def filter_backtrace(backtrace)
        Minitest.backtrace_filter
                .filter(backtrace)
                .reject {|line| Reporter.filters.any? { line.match?(_1) } }
                .select {|line| line.start_with?(Dir.pwd) }
      end

      private def print_result_code(result_code)
        result_code = color(result_code, COLOR_FOR_RESULT_CODE[result_code])
        io.print result_code
      end

      private def color(string, color = :default)
        if color_enabled?
          color = COLOR.fetch(color, 0)
          "\e[#{color}m#{string}\e[0m"
        else
          string
        end
      end

      private def color_enabled?
        @color_enabled
      end

      private def pluralize(word, count)
        case count
        when 0
          "no #{word}s"
        when 1
          "1 #{word}"
        else
          "#{count} #{word}s"
        end
      end

      private def running_rails?
        defined?(Rails) &&
        Rails.respond_to?(:version) &&
        Rails.version >= "5.0.0"
      end

      def bundler
        "bundle exec " if ENV.key?("BUNDLE_BIN_PATH")
      end

      private def build_test_command(test, result)
        location, line = test[:source_location]

        if ENV["MT_TEST_COMMAND"]
          cmd = ENV["MT_TEST_COMMAND"]

          return format(
            cmd,
            location: location,
            line: line,
            description: test[:description],
            name: result.name
          )
        end

        if running_rails?
          %[bin/rails test #{location}:#{line}]
        else
          %[#{bundler}rake TEST=#{location} TESTOPTS="--name=#{result.name}"]
        end
      end
    end
  end
end
