# frozen_string_literal: true

require "test_helper"

class ReporterTest < Test
  def build_test_case(&block)
    Class.new(Minitest::Test) do
      def self.name
        "Sample#{object_id}Test"
      end

      instance_eval(&block)
    end
  end

  def run_test_case(test_case)
    reporter = Minitest::Utils::Reporter.new(StringIO.new)
    reporter.start
    test_case.run(reporter)
    reporter.report

    Minitest::Runnable
      .runnables
      .delete_if {|klass| klass.name.to_s.start_with?("Sample") }
    Minitest::Test.tests.delete_if {|key| key.start_with?("Sample") }

    reporter.io.tap(&:rewind).read
  end

  test "displays slow test info" do
    lineno = __LINE__ + 4

    test_case = build_test_case do
      test "slow test" do
        slow_test
      end
    end

    out = run_test_case(test_case)

    exp = "   1) slow test [SKIPPED]\n      " \
          "Reason: slow test\n      " \
          "test/minitest/utils/reporter_test.rb:#{lineno}\n"

    assert_includes out, exp
  end

  test "displays failed test" do
    test_case = build_test_case do
      test "failed test" do
        assert false
      end
    end

    out = run_test_case(test_case)

    exp = "   1) failed test\n      " \
          "expected: truthy value\n      " \
          "got: false\n"

    assert_includes out, exp
  end

  test "displays replay command" do
    test_case = build_test_case do
      test "failed test" do
        assert false
      end
    end

    out = run_test_case(test_case)

    exp = "\nFailed Tests:\n\n" \
          "bundle exec rake TEST=test/minitest/utils/reporter_test.rb " \
          "TESTOPTS=\"--name=test_failed_test\""

    assert_includes out, exp
  end

  test "displays replay command with custom command" do
    lineno = __LINE__ + 11

    test_case = build_test_case do
      setup do
        ENV["MT_TEST_COMMAND"] =
          "location: %{location}\n" \
          "line: %{line}\n" \
          "description: %{description}\n" \
          "name: %{name}\n" \
      end

      test "failed test" do
        assert false
      end
    end

    out = run_test_case(test_case)

    exp = "location: test/minitest/utils/reporter_test.rb\n" \
          "line: #{lineno}\n" \
          "description: failed test\n" \
          "name: test_failed_test\n"

    assert_includes out, exp
  end

  test "skips slow tests when there are failing tests" do
    test_case = build_test_case do
      self.slow_threshold = -1

      test "it fails" do
        assert false
      end
    end

    out = run_test_case(test_case)

    refute_includes out, "Slow Tests:"
  end

  test "formats duration" do
    reporter = Minitest::Utils::Reporter.new

    assert_equal "1s", reporter.format_duration(1)
    assert_equal "10.5s", reporter.format_duration(10.5)

    assert_equal "100ms", reporter.format_duration(0.1)
    assert_equal "150ms", reporter.format_duration(0.15)

    assert_equal "100μs", reporter.format_duration(0.0001)
    assert_equal "150μs", reporter.format_duration(0.00015)

    assert_equal "100ns", reporter.format_duration(0.0000001)
    assert_equal "150ns", reporter.format_duration(0.00000015)
  end
end
