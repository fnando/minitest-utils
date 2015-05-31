require 'test_helper'

class MinitestUtilsTest < Minitest::Test
  test 'defines method name' do
    assert MinitestUtilsTest.instance_methods.include?(:test_defines_method_name)
  end

  test 'raises exception for duplicated method name' do
    assert_raises(RuntimeError) {
      Class.new(Minitest::Test) do
        test 'some test'
        test 'some test'
      end
    }
  end

  test 'flunks method without block' do
    test_case = Class.new(Minitest::Test) do
      test 'flunk test'
    end

    assert_raises(Minitest::Assertion) {
      test_case.new('test').test_flunk_test
    }
  end

  test 'defines setup steps' do
    setups = []

    test_case = Class.new(Minitest::Test) do
      setup { setups << 1 }
      setup { setups << 2 }
      setup { setups << 3 }

      test('do something') {}
    end

    test_case.new(Minitest::AbstractReporter).run

    assert_equal [1, 2, 3], setups
  end

  test 'defines teardown steps' do
    teardowns = []

    test_case = Class.new(Minitest::Test) do
      teardown { teardowns << 1 }
      teardown { teardowns << 2 }
      teardown { teardowns << 3 }

      test('do something') {}
    end

    test_case.new(Minitest::AbstractReporter).run

    assert_equal [1, 2, 3], teardowns
  end
end
