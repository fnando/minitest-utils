require 'test_helper'

class LetTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  $count = 0
  let(:count) { $count += 1 }

  test 'defines memoized reader (first test)' do
    assert_equal 0, $count
    5.times { assert_equal 1, count }
  end

  test 'defines memoized reader (second test)' do
    assert_equal 1, $count
    5.times { assert_equal 2, count }
  end

  test 'cannot override existing method' do
    exception, * = assert_raises {
      self.class.let(:count) { true }
    }, ArgumentError

    assert_equal 'Cannot define let(:count); method already defined by LetTest.', exception.message
  end

  test 'cannot start with test' do
    exception, * = assert_raises {
      self.class.let(:test_number) { true }
    }, ArgumentError

    assert_equal 'Cannot define let(:test_number); method cannot begin with \'test\'.', exception.message
  end
end
