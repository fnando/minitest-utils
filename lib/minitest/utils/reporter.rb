module Minitest
  module Utils
    class Reporter < Minitest::StatisticsReporter
      COLOR_FOR_RESULT_CODE = {
        '.' => :green,
        'E' => :red,
        'F' => :red,
        'S' => :yellow
      }

      COLOR = {
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34
      }

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
          failing_results.each.with_index(1) {|result, index| display_failing(result, index) }
          skipped_results.each.with_index(failing_results.size + 1) {|result, index| display_skipped(result, index) }
        end

        io.print "\n\n"
        io.puts statistics
        io.puts color(summary, color)

        if failing_results.any?
          io.puts "\nFailed Tests:\n"
          failing_results.each {|result| display_replay_command(result) }
          io.puts "\n\n"
        end
      end

      private

      def statistics
        "Finished in %.6fs, %.4f runs/s, %.4f assertions/s." %
          [total_time, count / total_time, assertions / total_time]
      end

      def summary # :nodoc:
        [
          pluralize('run', count),
          pluralize('assertion', assertions),
          pluralize('failure', failures),
          pluralize('error', errors),
          pluralize('skip', skips),
        ].join(', ')
      end

      def indent(text)
        text.gsub(/^/, '      ')
      end

      def display_failing(result, index)
        backtrace = backtrace(result.failure.backtrace)
        message = result.failure.message
        message = message.lines.tap(&:pop).join.chomp if result.error?

        str = "\n\n"
        str << color("%4d) %s" % [index, result_name(result.name)])
        str << "\n" << color(indent(message), :red)
        str << "\n" << color(backtrace, :blue)
        io.print str
      end

      def display_skipped(result, index)
        location = location(result.failure.location)
        str = "\n\n"
        str << color("%4d) %s [SKIPPED]" % [index, result_name(result.name)], :yellow)
        str << "\n" << indent(color(location, :yellow))
        io.print str
      end

      def display_replay_command(result)
        location = find_test_file(result)
        return if location.empty?

        command = %[rake TEST=#{location} TESTOPTS="--name=#{result.name}"]
        str = "\n"
        str << color(command, :red)

        io.print str
      end

      def find_test_file(result)
        filter_backtrace(result.failure.backtrace)
          .find {|line| line.match(%r((test|spec)/.*?_(test|spec).rb)) }
          .to_s
          .gsub(/:\d+.*?$/, '')
      end

      def backtrace(backtrace)
        backtrace = filter_backtrace(backtrace).map {|line| location(line, true) }
        return if backtrace.empty?
        indent(backtrace.join("\n")).gsub(/^(\s+)/, "\\1# ")
      end

      def location(location, include_line_number = false)
        regex = include_line_number ? /^([^:]+:\d+)/ : /^([^:]+)/
        location = File.expand_path(location[regex, 1])

        return location unless location.start_with?(Dir.pwd)

        location.gsub(%r[^#{Regexp.escape(Dir.pwd)}/], '')
      end

      def filter_backtrace(backtrace)
        Minitest.backtrace_filter.filter(backtrace)
      end

      def result_name(name)
        name
          .gsub(/^test(_\d+)?_/, '')
          .gsub(/_/, ' ')
      end

      def print_result_code(result_code)
        result_code = color(result_code, COLOR_FOR_RESULT_CODE[result_code])
        io.print result_code
      end

      def color(string, color = :default)
        if color_enabled?
          color = COLOR.fetch(color, 0)
          "\e[#{color}m#{string}\e[0m"
        else
          string
        end
      end

      def color_enabled?
        @color_enabled
      end

      def pluralize(word, count)
        case count
        when 0
          "no #{word}s"
        when 1
          "1 #{word}"
        else
          "#{count} #{word}s"
        end
      end
    end
  end
end
