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
end
