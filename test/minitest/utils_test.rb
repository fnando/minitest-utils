# frozen_string_literal: true

require "test_helper"

class MinitestUtilsTest < Minitest::Test
  def capture_exception
    yield
  rescue Exception => error # rubocop:disable Lint/RescueException
    error
  end

  test "defines method name" do
    assert_includes(
      MinitestUtilsTest.instance_methods, :test_defines_method_name
    )
  end

  test "improves assert message" do
    exception = capture_exception { assert nil }

    assert_equal "expected: truthy value\ngot: nil", exception.message
  end

  test "improves refute message" do
    exception = capture_exception { refute 1234 }

    assert_equal "expected: falsy value\ngot: 1234", exception.message
  end

  test "raises exception for duplicated method name" do
    assert_raises(RuntimeError) do
      Class.new(Minitest::Test) do
        test "some test"
        test "some test"
      end
    end
  end

  test "defines test with weird names" do
    test_case = Class.new(Minitest::Test) do
      test("with parens (nice)") { assert true }
      test("with brackets [nice]") { assert true }
      test("with   multiple   spaces") { assert true }
      test("with   underscores   __") { assert true }
      test("with UPPERCASE") { assert true }
    end

    assert_includes test_case.instance_methods, :test_with_parens_nice
    assert_includes test_case.instance_methods, :test_with_brackets_nice
    assert_includes test_case.instance_methods, :test_with_multiple_spaces
    assert_includes test_case.instance_methods, :test_with_underscores
    assert_includes test_case.instance_methods, :test_with_uppercase
  end

  test "flunks method without block" do
    test_case = Class.new(Minitest::Test) do
      test "flunk test"
    end

    assert_raises(Minitest::Assertion) do
      test_case.new("test").test_flunk_test
    end
  end

  test "defines setup steps" do
    setups = []

    test_case = Class.new(Minitest::Test) do
      setup { setups << 1 }
      setup { setups << 2 }
      setup { setups << 3 }

      test("do something") { assert(true) }
    end

    test_case.new(Minitest::AbstractReporter).run

    assert_equal [1, 2, 3], setups
  end

  test "defines teardown steps" do
    teardowns = []

    test_case = Class.new(Minitest::Test) do
      teardown { teardowns << 1 }
      teardown { teardowns << 2 }
      teardown { teardowns << 3 }

      test("do something") { assert(true) }
    end

    test_case.new(Minitest::AbstractReporter).run

    assert_equal [1, 2, 3], teardowns
  end
end
