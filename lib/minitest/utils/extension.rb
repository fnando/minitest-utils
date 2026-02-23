# frozen_string_literal: true

module Minitest
  module Utils
    module Assertions
      def assert(test, message = nil)
        message ||= "expected: truthy value\ngot: #{mu_pp(test)}"
        super
      end

      def refute(test, message = nil)
        message ||= "expected: falsy value\ngot: #{mu_pp(test)}"
        super
      end

      def diff(expected, actual)
        expected = mu_pp_for_diff(expected)
        actual   = mu_pp_for_diff(actual)

        a = expected.scan(/\w+|\W+/)
        b = actual.scan(/\w+|\W+/)

        exp_out = +""
        act_out = +""

        Diff::LCS
          .sdiff(a, b)
          .chunk_while {|a, b| a.action == b.action }
          .each do |group|
            action  = group.first.action
            old_str = group.filter_map(&:old_element).join
            new_str = group.filter_map(&:new_element).join

            case action
            when "="
              exp_out << old_str
              act_out << new_str
            when "-"
              exp_out << Utils.color(old_str, :red, bgcolor: :red)
            when "+"
              act_out << Utils.color(new_str, :green, bgcolor: :green)
            when "!"
              exp_out << Utils.color(old_str, :red, bgcolor: :red)
              act_out << Utils.color(new_str, :green, bgcolor: :green)
            end
          end

        "#{Utils.color('expected: ', :red)} #{exp_out}\n" \
          "#{Utils.color('  actual: ', :red)} #{act_out}"
      end
    end
  end

  class Test
    include ::Minitest::Utils::Assertions

    def self.tests
      @tests ||= {}
    end

    def slow_test
      return if ENV["MT_RUN_SLOW_TESTS"] || Minitest.options[:slow]

      skip "slow test"
    end

    def self.test_method_name(description)
      method_name = description.downcase
                               .gsub(/[^a-z0-9]+/, "_")
                               .gsub(/^_+/, "")
                               .gsub(/_+$/, "")
                               .squeeze("_")
      :"test_#{method_name}"
    end

    # This hook handles methods defined directly with `def test_`.
    def self.method_added(method_name)
      super

      test_name = method_name.to_s

      return unless test_name.start_with?("test_")

      klass = name
      id = "#{klass}##{method_name}"
      description = method_name.to_s.delete_prefix("test_").tr("_", " ")

      return if Test.tests[id]

      file_path, lineno = instance_method(method_name).source_location

      source_location = [
        Pathname(file_path).relative_path_from(Pathname(Dir.pwd)),
        lineno
      ]

      Test.tests[id] = {
        id:,
        description:,
        name: test_name,
        source_location:,
        time: nil,
        slow_threshold:
      }
    end

    def self.test(description, &block)
      source_location = caller_locations(1..1).first
      source_location = [
        Pathname(source_location.path).relative_path_from(Pathname(Dir.pwd)),
        source_location.lineno
      ]

      klass = name
      test_name = test_method_name(description)
      defined = method_defined?(test_name)
      id = "#{klass}##{test_name}"

      Test.tests[id] = {
        id:,
        description:,
        name: test_name,
        source_location:,
        time: nil,
        slow_threshold:
      }

      testable = proc do
        err = nil
        t0 = Minitest.clock_time
        instance_eval(&block)
      rescue StandardError => error
        err = error
      ensure
        Test.tests["#{klass}##{test_name}"][:time] = Minitest.clock_time - t0
        raise err if err
      end

      raise "#{test_name} is already defined in #{self}" if defined

      if block
        define_method(test_name, &testable)
      else
        define_method(test_name) do
          flunk "No implementation provided for #{name}"
        end
      end
    end

    def self.setup(&block)
      mod = Module.new
      mod.module_eval do
        define_method :setup do
          super()
          instance_eval(&block)
        end
      end

      include mod
    end

    def self.teardown(&block)
      mod = Module.new
      mod.module_eval do
        define_method :teardown do
          super()
          instance_eval(&block)
        end
      end

      include mod
    end

    def self.let(name, &block)
      target = begin
        instance_method(name)
      rescue StandardError
        nil
      end

      message = "Cannot define let(:#{name});"

      if name.to_s.start_with?("test")
        raise ArgumentError, "#{message} method cannot begin with 'test'."
      end

      if target
        raise ArgumentError,
              "#{message} method already defined by #{target.owner}."
      end

      define_method(name) do
        @_memoized ||= {}
        @_memoized.fetch(name) {|k| @_memoized[k] = instance_eval(&block) }
      end
    end
  end
end
