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

    def self.test(name, &block)
      test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
      defined = method_defined? test_name

      raise "#{test_name} is already defined in #{self}" if defined

      if block_given?
        define_method(test_name, &block)
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
  end
end
