#!/usr/bin/env ruby
$VERBOSE = true if $0 == __FILE__

require 'test/unit'
require 'rmock'


module RMock::Test

  class MockTest < Test::Unit::TestCase
    include ::Test::Unit
    include RMock

    def test_stub_call_with_no_arguments_returns_nil
      mock = Mock.new
      mock.stubs.ping
      assert_nil mock.proxy.ping
    end

    def test_stub_call_with_no_arguments_will_return_preset_value
      mock = Mock.new
      mock.stubs.ping.as {'pong'}
      assert_equal 'pong', mock.proxy.ping
    end

    def test_can_construct_mock_with_a_block
      mock = Mock.new do |m|
        m.stubs.ping.as {'pong'}
      end
      assert_equal 'pong', mock.proxy.ping
    end

    def test_error_raised_if_missing_mock_method_invoked
      proxy = Mock.new.proxy
      assert_raise NoMethodError do proxy.ping end
    end

    def test_verify_after_calling_no_stubs_does_nothing
      Mock.new.verify
      Mock.new { |m| m.stubs.ping }.verify
    end

    def test_verify_after_calling_stubs_does_nothing
      mock = Mock.new do |m| m.stubs.ping end
      mock.proxy.ping
      mock.verify
    end

    def test_can_expect_and_call_method_with_no_arguments
      mock = Mock.new do |m| m.expects.bing end
      assert_nil mock.proxy.bing
    end

    def test_verify_after_calling_expected_method_with_no_args
      mock = Mock.new do |m| m.expects.bing end
      mock.proxy.bing
      mock.verify
    end

    def test_verify_fails_when_expected_method_not_called
      mock = Mock.new do |m| m.expects.bing end
      assert_raise AssertionFailedError do mock.verify end
    end

    def test_can_use_mock_with_block_in_order_to_have_verify_called_automatically
      mock = Mock.new do |m|
        m.expects.some_method
        m.expects.some_other_method
      end
      assert_raise AssertionFailedError do
        mock.use { |o| o.some_method }
      end
    end

    def test_can_call_a_stub_twice
      mock = Mock.new do |m| m.stubs.bing.as {'crosby'} end
      2.times do assert_equal 'crosby', mock.proxy.bing end
    end

    def test_can_stub_a_method_with_an_argument
      mock = Mock.new do |m| m.stubs.bing('who?').as {'crosby'} end
      assert_equal 'crosby', mock.proxy.bing('who?')
    end

    def test_can_stub_a_method_twice_with_different_args
      mock = Mock.new do |m|
        m.stubs.last_name?('marlon').as {'brando'}
        m.stubs.last_name?('jimmy').as {'cagney'}
      end
      assert_equal 'cagney', mock.proxy.last_name?('jimmy')
      assert_equal 'brando', mock.proxy.last_name?('marlon')
    end

    def test_can_expect_a_method_with_an_argument
      mock = Mock.new
      mock.expects.who_am_i?('Jackie').as { 'Chan' }
      mock.use do |o|
        assert_equal 'Chan', o.who_am_i?('Jackie')
      end
    end

    def test_error_raised_if_expected_method_called_twice
      mock = Mock.new do |m| m.expects.some_method end
      mock.proxy.some_method
      assert_raise AssertionFailedError do mock.proxy.some_method end
    end

    def test_can_stub_pre_existing_methods
      mock = Mock.new do |m| m.stubs.to_s.as {'foobar'} end
      assert_equal 'foobar', mock.proxy.to_s
    end

    def test_can_stub_call_that_expects_a_block
      mock = Mock.new do |m| m.stubs.each(Proc) end
      mock.proxy.each {}
    end

    def test_error_raised_if_block_not_given_to_stubbed_method_wanting_a_block
      mock = Mock.new do |m| m.stubs.each(Proc) end
      assert_raise AssertionFailedError do
        mock.proxy.each
      end
    end

    def test_can_use_ranges_to_specify_argument_matches
      mock = Mock.new do |m|
        m.stubs.between_1_and_5?(1..5).as { true }
        m.stubs.between_1_and_5?(6..10).as { false }
      end
      mock.use do |o|
        assert_equal true, o.between_1_and_5?(3)
        assert_equal false, o.between_1_and_5?(7)
      end
    end

    def test_can_stub_constants
      mock = Mock.new do |m| m.stubs.FOOBAR.as { "jimini" } end
      assert_equal 'jimini', mock.proxy.FOOBAR
    end

    def test_can_expect_constants
      mock = Mock.new do |m| m.expects.FOOBAR.as { "jimini" } end
      assert_equal 'jimini', mock.proxy.FOOBAR
    end

  end

#  class AutoMockTest < Test::Unit::TestCase
#    include RMock::TestCaseHelpers
#
#    def test_foo
#      m = new_mock
#      m.expects.foo.as { 'bar' }
#    end
#
#  end

  # TODO:
  #  * Clearer error messages
  #  * Namespaces for constants
  #  * Intercepting top-level calls such as File#open
  #  * Explicit test for use of === in arg matching
  #  * Allow specification of call order
end
