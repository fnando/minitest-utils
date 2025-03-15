# frozen_string_literal: true

gem "minitest"
require "minitest"
require_relative "../utils"
require "optparse"
require "io/console"

module Minitest
  module Utils
    class CLI
      MATCHER =
        /^(\s+(?:(?<short>-[a-zA-Z]+), )?(?<long>[^ ]+) +)(?<description>.*?)$/ # rubocop:disable Lint/MixedRegexpCaptureTypes

      class << self
        attr_accessor :loaded_via_bundle_exec
      end

      def initialize(args)
        @args = args
      end

      def indent(text)
        text.gsub(/^/, "  ")
      end

      def start
        OptionParser.new do |parser|
          parser.banner = ""

          parser.on_tail("-h", "--help", "Show this message") do
            matches = parser.to_a.map do |line|
              line.match(MATCHER).named_captures.transform_keys(&:to_sym)
            end
            print_help(matches)
            exit
          end

          parser.on("-n", "--name=NAME",
                    "Run tests that match this name") do |v|
            options[:name] = v
          end

          parser.on("-s", "--seed=SEED", "Sets fixed seed.") do |v|
            options[:seed] = v
          end

          parser.on("--slow", "Run slow tests.") do |v|
            options[:slow] = v
          end

          parser.on("--hide-slow", "Hide list of slow tests.") do |v|
            options[:hide_slow] = v
          end

          parser.on("--slow-threshold=THRESHOLD",
                    "Set the slow threshold (in seconds)") do |v|
            options[:slow_threshold] = v.to_f
          end

          parser.on(
            "-e",
            "--exclude=PATTERN",
            "Exclude /regexp/ or string from run."
          ) do |v|
            options[:exclude] = v
          end
        end.parse!(@args)

        run
      end

      def test_dir
        File.join(Dir.pwd, "test")
      end

      def spec_dir
        File.join(Dir.pwd, "spec")
      end

      def lib_dir
        File.join(Dir.pwd, "lib")
      end

      def test_dir?
        File.directory?(test_dir)
      end

      def spec_dir?
        File.directory?(spec_dir)
      end

      def lib_dir?
        File.directory?(lib_dir)
      end

      def run
        $LOAD_PATH << lib_dir if lib_dir?
        $LOAD_PATH << test_dir if test_dir?
        $LOAD_PATH << spec_dir if spec_dir?

        puts "\nNo tests found." if files.empty?

        files.each {|file| require(file) }

        bundler = "bundle exec " if self.class.loaded_via_bundle_exec

        ENV["MT_TEST_COMMAND"] =
          "#{bundler}mt %{location}:%{line} # %{description}"

        ARGV.clear
        ARGV.push(*minitest_args)
        Minitest.autorun
      end

      def minitest_args
        args = []
        args += ["--seed", options[:seed]]
        args += ["--exclude", options[:exclude]] if options[:exclude]
        args += ["--slow", options[:slow]] if options[:slow]
        args += ["--name", "/#{only.join('|')}/"] unless only.empty?
        args += ["--hide-slow"] if options[:hide_slow]

        if options[:slow_threshold]
          threshold = options[:slow_threshold].to_s
          threshold = threshold.gsub(/\.0+$/, "").delete_suffix(".")
          args += ["--slow-threshold", threshold]
        end

        args.map(&:to_s)
      end

      def files
        @files ||= begin
          files = @args
          files += %w[test spec] if files.empty?
          files
            .flat_map { expand_entry(_1) }
            .reject { ignored_file?(_1) }
        end
      end

      def ignored_files
        @ignored_files ||= if File.file?(".minitestignore")
                             File.read(".minitestignore")
                                 .lines
                                 .map(&:strip)
                                 .reject { _1.start_with?("#") }
                           else
                             []
                           end
      end

      def ignored_file?(file)
        ignored_files.any? { file.include?(_1) }
      end

      def only
        @only ||= []
      end

      def expand_entry(entry)
        entry = extract_entry(entry)

        if File.directory?(entry)
          Dir[
            File.join(entry, "**", "*_test.rb"),
            File.join(entry, "**", "*_spec.rb")
          ]
        else
          Dir[entry]
        end
      end

      def extract_entry(entry)
        entry = File.expand_path(entry)
        return entry unless entry.match?(/:\d+$/)

        entry, line = entry.split(":")
        line = line.to_i
        return entry unless File.file?(entry)

        content = File.read(entry)
        text = content.lines[line - 1].chomp.strip

        method_name = if text =~ /^\s*test\s+(['"])(.*?)\1\s+do\s*$/
                        Test.test_method_name(::Regexp.last_match(2))
                      elsif text =~ /^def\s+(test_.+)$/
                        ::Regexp.last_match(1)
                      end

        if method_name
          class_names =
            content.scan(/^\s*class\s+([^<]+)/).flatten.map(&:strip)

          class_name = class_names.find do |name|
            name.end_with?("Test")
          end

          only << "#{class_name}##{method_name}" if class_name
        end

        entry
      end

      def options
        @options ||= {
          seed: (ENV["SEED"] || srand).to_i % 0xFFFF
        }
      end

      BANNER = <<~TEXT
        A better test runner for Minitest.

        You can run specific files by using `file:number`.

        $ mt test/models/user_test.rb:42

        You can also run files by the test name (caveat: you need to underscore the name):

        $ mt test/models/user_test.rb --name /validations/

        You can also run specific directories:

        $ mt test/models

        To exclude tests by name, use --exclude:

        $ mt test/models --exclude /validations/
      TEXT

      COLOR = {
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        gray: 37
      }.freeze

      private def color(string, color = :default)
        return string if string.empty?

        if $stdout.tty?
          color = COLOR.fetch(color, 0)
          "\e[#{color}m#{string}\e[0m"
        else
          string
        end
      end

      def print_help(matches)
        io = StringIO.new
        matches.sort_by! { _1["long"] }
        short_size = matches.map { _1[:short].to_s.size }.max
        long_size = matches.map { _1[:long].to_s.size }.max

        io << indent(color("Usage:", :green))
        io << indent(color("mt [OPTIONS] [FILES|DIR]...", :blue))
        io << "\n\n"
        io << indent("A better test runner for Minitest.")
        io << "\n\n"
        file_line = color("file:number", :yellow)
        io << indent("You can run specific files by using #{file_line}.")
        io << "\n\n"
        io << indent(color("$ mt test/models/user_test.rb:42", :yellow))
        io << "\n\n"
        io << indent("You can run files by the test name.")
        io << "\n"
        io << indent("Caveat: you need to underscore the name.")
        io << "\n\n"
        io << indent(
          color("$ mt test/models/user_test.rb --name /validations/", :yellow)
        )
        io << "\n\n"
        io << indent("You can also run specific directories:")
        io << "\n\n"
        io << indent(color("To exclude tests by name, use --exclude:", :yellow))
        io << "\n\n"
        io << indent("To ignore files, you can use a `.minitestignore`.")
        io << "\n"
        io << indent("Each line can be a partial file/dir name.")
        io << "\n"
        io << indent("Lines startin with # are ignored.")
        io << "\n\n"
        io << indent(color("# This is a comment", :yellow))
        io << "\n"
        io << indent(color("test/fixtures", :yellow))
        io << "\n\n"
        io << indent(color("Options:", :green))
        io << "\n"

        matches.each do |match|
          match => { short:, long:, description: }

          io << "  "
          io << (" " * (short_size - short.to_s.size))
          io << color(short, :blue) if short
          io << "  " unless short
          io << ", " if short
          io << color(long.to_s, :blue)
          io << (" " * (long_size - long.to_s.size + 4))
          io << description
          io << "\n"
        end

        puts io.tap(&:rewind).read
      end
    end
  end
end
