module Minitest
  module Utils
    class Reporter < Minitest::StatisticsReporter
      def statistics
        stats = super
      end

      def record(result)
        super
        print_result_code(result.result_code)
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
        command = %[rake TEST=#{location} TESTOPTS="--name=#{result.name}"]
        str = "\n"
        str << color(command, :red)

        io.print str
      end

      def find_test_file(result)
        filter_backtrace(result.failure.backtrace)
          .find {|line| line.match(%r(^(test|spec)/.*?_(test|spec).rb)) }
          .gsub(/:\d+.*?$/, '')
      end

      def backtrace(backtrace)
        backtrace = filter_backtrace(backtrace).map {|line| location(line) }
        return if backtrace.empty?
        indent(backtrace.join("\n")).gsub(/^(\s+)/, "\\1# ")
      end

      def location(location)
        location = File.expand_path(location[/^([^:]+)/, 1])

        return location unless location.start_with?(Dir.pwd)

        location.gsub(%r[^#{Regexp.escape(Dir.pwd)}/], '')
      end

      def filter_backtrace(backtrace)
        Minitest.backtrace_filter.filter(backtrace)
      end

      def result_name(name)
        name
          .gsub(/^test_\d+_/, '')
          .gsub(/_/, ' ')
      end

      def print_result_code(result_code)
        result_code = case result_code
                      when '.'
                        color('.', :green)
                      when 'S'
                        color('S', :yellow)
                      when 'F'
                        color('F', :red)
                      when 'E'
                        color('E', :red)
                      else
                        color(result_code)
                      end

        io.print result_code
      end

      def color(string, color = :default)
        case color
        when :red
          "\e[31m#{string}\e[0m"
        when :green
          "\e[32m#{string}\e[0m"
        when :yellow
          "\e[33m#{string}\e[0m"
        when :blue
          "\e[34m#{string}\e[0m"
        else
          "\e[0m#{string}"
        end
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
