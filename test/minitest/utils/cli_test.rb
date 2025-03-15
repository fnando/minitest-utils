# frozen_string_literal: true

require "test_helper"

class CLITest < Test
  let(:bin) { "../exe/mt" }

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  setup do
    create_file "tmp/test/test_helper.rb", <<~RUBY
      require_relative "../../lib/minitest/utils"
    RUBY
  end

  teardown do
    FileUtils.rm_rf("tmp")
  end

  test "runs all tests" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "it passes" do
          assert true
        end
      end
    RUBY

    create_file "tmp/test/another_test.rb", <<~RUBY
      require "test_helper"

      class AnotherTest < Minitest::Test
        test "it passes" do
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin }
    end

    assert_match(/^\.\.\n/, out)
    assert_includes out, "\n2 runs, 2 assertions, no failures, no errors, " \
                         "no skips\n"
  end

  test "runs specified file" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "it passes" do
          assert true
        end
      end
    RUBY

    create_file "tmp/test/another_test.rb", <<~RUBY
      require "test_helper"

      class AnotherTest < Minitest::Test
        test "it passes" do
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "test/some_test.rb" }
    end

    assert_match(/^\.\n/, out)
    assert_includes out, "\n1 run, 1 assertion, no failures, no errors, " \
                         "no skips\n"
  end

  test "runs specified test (using block)" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "passes" do
          assert true
        end

        test "and this one too" do
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "test/some_test.rb:4" }
    end

    assert_match(/^\.\n/, out)
    assert_includes out, "\n1 run, 1 assertion, no failures, no errors, " \
                         "no skips\n"
  end

  test "runs specified test (using def)" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "it passes" do
          assert true
        end

        def test_and_this_passes_too
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "test/some_test.rb:8" }
    end

    assert_match(/^\.\n/, out)
    assert_includes out, "\n1 run, 1 assertion, no failures, no errors, " \
                         "no skips\n"
  end

  test "sets a seed" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "it passes" do
          assert true
        end

        def test_and_this_passes_too
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "--seed", "1234" }
    end

    assert_includes out, "Run options: --seed 1234"
  end

  test "includes slow tests" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "it passes" do
          slow_test
          assert true
        end

        def test_and_this_passes_too
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "--seed", "1234", "--slow" }
    end

    assert_includes out, "Run options: --seed 1234 --slow\n"
    assert_match(/^..\n/, out)
    assert_includes out, "\n2 runs, 2 assertions, no failures, no errors, " \
                         "no skips\n"
  end

  test "shows list of slow tests" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        self.slow_threshold = 0.1

        test "so slow" do
          sleep 0.1
          assert true
        end

        def test_even_more_slow
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "--seed", "1234" }
    end

    assert_includes out, "\nSlow Tests:\n"
    assert_match(/\n1\) so slow \(.+(μs|ms|s)\)\n/, out)
    refute_match(/\n2\) even more slow \(.+(μs|ms|s)\)\n/, out)
  end

  test "hides list of slow tests" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        self.slow_threshold = -1

        test "so slow" do
          assert true
        end

        def test_even_more_slow
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") { system bin, "--seed", "1234", "--hide-slow" }
    end

    assert_includes out, "Run options: --seed 1234 --hide-slow\n"
    refute_includes out, "\nSlow Tests:\n"
    refute_match(/\n1\) so slow \(.+(μs|ms|s)\)\n/, out)
    refute_match(/\n2\) even more slow \(.+(μs|ms|s)\)\n/, out)
  end

  test "sets slow threshold" do
    create_file "tmp/test/some_test.rb", <<~RUBY
      require "test_helper"

      class SomeTest < Minitest::Test
        test "so slow" do
          assert true
        end

        def test_even_more_slow
          assert true
        end
      end
    RUBY

    out, _ = capture_subprocess_io do
      Dir.chdir("tmp") do
        system bin, "--seed", "1234", "--slow-threshold", "-1"
      end
    end

    assert_includes out,
                    "Run options: --seed 1234 --slow-threshold -1\n"
    assert_includes out, "\nSlow Tests:\n"
  end
end
