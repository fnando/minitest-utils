# frozen_string_literal: true

module Minitest
  module Utils
    module Assertions
      def assert(test, message = nil)
        message ||= "expected: truthy value\ngot: #{mu_pp(test)}"
        super(test, message)
      end

      def refute(test, message = nil)
        message ||= "expected: falsy value\ngot: #{mu_pp(test)}"
        super(test, message)
      end
    end
  end

  class Test
    include ::Minitest::Utils::Assertions

    def self.tests
      @tests ||= {}
    end

    def self.test(name, &block)
      source_location = caller_locations(1..1).first
      source_location = [
        Pathname(source_location.path).relative_path_from(Pathname(Dir.pwd)),
        source_location.lineno
      ]

      klass = self.name
      method_name = name.downcase
                        .gsub(/[^a-z0-9]+/, "_")
                        .gsub(/^_+/, "")
                        .gsub(/_+$/, "").squeeze("_")
      test_name = "test_#{method_name}".to_sym
      defined = method_defined?(test_name)

      Test.tests["#{klass}##{test_name}"] = {
        name: name,
        source_location:,
        benchmark: nil
      }

      testable = proc do
        benchmark = Benchmark.measure { instance_eval(&block) }
        Test.tests["#{klass}##{test_name}"][:benchmark] = benchmark
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
