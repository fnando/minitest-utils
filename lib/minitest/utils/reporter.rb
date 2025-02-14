# frozen_string_literal: true

module Minitest
  module Utils
    class Reporter < Minitest::StatisticsReporter
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
        blue: 34
      }.freeze

      def initialize(*)
        super
        @color_enabled = io.respond_to?(:tty?) && io.tty?
      end

      def record(result)
        super
        print_result_code(result.result_code)
      end

      def start
        super
        io.puts "Run options: #{options[:args]}"
        io.puts
        io.puts "# Running:"
        io.puts
      end

      def report
        super
        io.sync = true

        failing_results = results.reject(&:skipped?)
        skipped_results = results.select(&:skipped?)

        color = :green
        color = :yellow if skipped_results.any?
        color = :red if failing_results.any?

        if failing_results.any? || skipped_results.any?
          failing_results.each.with_index(1) do |result, index|
            display_failing(result, index)
          end

          skipped_results
            .each
            .with_index(failing_results.size + 1) do |result, index|
            display_skipped(result, index)
          end
        end

        io.print "\n\n"
        io.puts statistics
        io.puts color(summary, color)

        return unless failing_results.any?

        io.puts "\nFailed Tests:\n"
        failing_results.each {|result| display_replay_command(result) }
        io.puts "\n\n"
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

        output = ["\n\n"]
        output << color(format("%4d) %s", index, result_name(result.name)))
        output << "\n" << color(indent(message), :red)
        output << "\n" << color(backtrace, :blue)
        io.print output.join
      end

      private def display_skipped(result, index)
        location = location(result.failure.location)
        output = ["\n\n"]
        output << color(
          format("%4d) %s [SKIPPED]", index, result_name(result.name)), :yellow
        )
        output << "\n" << indent(color(location, :yellow))
        io.print output.join
      end

      private def display_replay_command(result)
        location, line = find_test_file(result)
        return if location.empty?

        command = build_test_command(location, line, result)

        output = ["\n"]
        output << color(command, :red)

        io.print output.join
      end

      private def find_test_file(result)
        location, line = if result.respond_to?(:source_location)
                           result.source_location
                         else
                           result.method(result.name).source_location
                         end

        location = location.gsub(%r{^.*?/((?:test|spec)/.*?)$}, "\\1")

        [location, line]
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
        location = File.expand_path(location[regex, 1])

        return location unless location.start_with?(Dir.pwd)

        location.gsub(%r{^#{Regexp.escape(Dir.pwd)}/}, "")
      end

      private def filter_backtrace(backtrace)
        Minitest.backtrace_filter.filter(backtrace)
      end

      private def result_name(name)
        name
          .gsub(/^test(_\d+)?_/, "")
          .tr("_", " ")
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

      private def build_test_command(location, line, result)
        if ENV["MINITEST_TEST_COMMAND"]
          return format(
            ENV["MINITEST_TEST_COMMAND"],
            location: location,
            line: line,
            name: result.name
          )
        end

        if running_rails?
          %[bin/rails test #{location}:#{line}]
        else
          bundle = "bundle exec " if defined?(Bundler)
          %[#{bundle}rake TEST=#{location} TESTOPTS="--name=#{result.name}"]
        end
      end
    end
  end
end
