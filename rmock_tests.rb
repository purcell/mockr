#!/usr/bin/env ruby
$VERBOSE = true

require 'test/unit'
require 'rmock'


module RMock::Test

  class MockTest < Test::Unit::TestCase
    include ::Test::Unit
    include RMock

    def test_stub_call_with_no_arguments_returns_nil
      mock = Mock.new
      mock.stub_call(:ping)
      assert_nil mock.proxy.ping
    end

    def test_stub_call_with_no_arguments_will_return_preset_value
      mock = Mock.new
      mock.stub_call(:ping).will {'pong'}
      assert_equal 'pong', mock.proxy.ping
    end

    def test_can_construct_mock_with_a_block
      mock = Mock.new do |m|
        m.stub_call(:ping).will {'pong'}
      end
      assert_equal 'pong', mock.proxy.ping
    end

    def test_error_raised_if_missing_stub_invoked  # TODO: assertion error here?
      proxy = Mock.new.proxy
      assert_raise NoMethodError do proxy.ping end
    end

    def test_verify_after_calling_no_stubs_does_nothing
      Mock.new.verify
      Mock.new { |m| m.stub_call(:ping) }.verify
    end

    def test_verify_after_calling_stubs_does_nothing
      mock = Mock.new { |m| m.stub_call(:ping) }
      mock.proxy.ping
      mock.verify
    end

    def test_can_expect_and_call_method_with_no_arguments
      mock = Mock.new do |m|
        m.expect_call(:bing)
      end
      assert_nil mock.proxy.bing
    end

    def test_verify_after_calling_expected_method_with_no_args
      mock = Mock.new do |m|
        m.expect_call(:bing)
      end
      mock.proxy.bing
      mock.verify
    end

    def test_verify_fails_when_expected_method_not_called
      mock = Mock.new do |m|
        m.expect_call(:bing)
      end
      assert_raise AssertionFailedError do mock.verify end
    end

    def test_can_call_a_stub_twice
      mock = Mock.new do |m|
        m.stub_call(:bing).will {'crosby'}
      end
      2.times do assert_equal 'crosby', mock.proxy.bing end
    end

    def test_can_stub_a_method_with_an_argument
      mock = Mock.new do |m|
        m.stub_call(:bing, 'who?').will {'crosby'}
      end
      assert_equal 'crosby', mock.proxy.bing('who?')
    end

    def test_can_stub_a_method_twice_with_different_args
      mock = Mock.new do |m|
        m.stub_call(:last_name?, 'marlon').will {'brando'}
        m.stub_call(:last_name?, 'jimmy').will {'cagney'}
      end
      assert_equal 'cagney', mock.proxy.last_name?('jimmy')
      assert_equal 'brando', mock.proxy.last_name?('marlon')
    end

    def test_error_raised_if_expected_method_called_twice
      mock = Mock.new do |m|
        m.expect_call(:some_method)
      end
      mock.proxy.some_method
      assert_raise AssertionFailedError do mock.proxy.some_method end
    end

    def test_can_use_mock_with_block_in_order_to_have_verify_called_automatically
      mock = Mock.new do |m|
        m.expect_call(:some_method)
        m.expect_call(:some_other_method)
      end
      assert_raise AssertionFailedError do
        mock.use { |o| o.some_method }
      end
    end

    def test_can_stub_pre_existing_methods
      mock = Mock.new do |m|
        m.stub_call(:to_s).will {'foobar'}
      end
      assert_equal 'foobar', mock.proxy.to_s
    end

    def test_can_stub_call_that_expects_a_block
      mock = Mock.new do |m|
        m.stub_call(:each, Proc)
      end
      mock.proxy.each {}
    end

    def test_error_raised_if_block_not_provided_to_stubbed_method_that_wants_a_block
      mock = Mock.new do |m|
        m.stub_call(:each, Proc)
      end
      assert_raise AssertionFailedError do
        mock.proxy.each
      end
    end

    def test_can_define_stubs_using_a_pseudo_call
      mock = Mock.new do |m|
        m.stub.ping.will { 'pong' }
      end
      assert_equal 'pong', mock.proxy.ping
    end

    def test_can_define_stubs_using_a_pseudo_call_with_params
      mock = Mock.new do |m|
        m.stub.ping('one').will { 'two' }
        m.stub.ping('three').will { 'four' }
      end
      assert_equal 'two', mock.proxy.ping('one')
    end
  end



  # TODO:
  #  * Clearer error messages
end
