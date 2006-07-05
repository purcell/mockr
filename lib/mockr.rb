require 'test/unit'

module Mockr

  ################################################################################

  class Mock
    include ::Test::Unit

    attr_reader :proxy

    # Create a new Mock, with an optional initialisation block.  If provided,
    # the block will be called with the new instance.
    #
    # Example:
    #  Mock.new do |m|
    #    m.stubs.some_method
    #  end
    def initialize &block
      @expectations = []
      @satisfied_expectations = []
      create_proxy
      block.call(self) if block
    end

    # Tell the mock to respond to a call, optionally with specific parameters.
    #
    # The call can be called an arbitrary number of times by the client code
    # without affecting the result of #verify.
    #
    # Parameters to the expected call will be used to match the actual parameters
    # passed by client code later.  The match (===) method of the expectation
    # parameter is used to determine whether the client's call matched this
    # anticipated call.
    #
    # Examples:
    #  mock.stubs.bang!
    #  mock.stubs.ping.as { :pong }
    #  mock.stubs.hello?(/World/).as { true }  # Respond with +true+ if called with a parameter for which <tt>/World/ === param</tt> is true
    def stubs
      CallRecorder.new(method(:stub_call))
    end

    # Tell the mock to expect a call, optionally with specific parameters.
    # If the call has not been made when #verify is called, #verify will fail
    # with a Test::Unit::AssertionFailed.
    #
    # Parameters to the expected call will be used to match the actual parameters
    # passed by client code later.  The match (===) method of the expectation
    # parameter is used to determine whether the client's call matched this anticipated
    # call.
    #
    # Examples:
    #  mock.expects.bang!
    #  mock.expects.ping.as { :pong }
    #  mock.expects.safe?(1..10).as { true }  # Expect a call with a parameter for which <tt>(1..10) === param</tt>
    def expects
      CallRecorder.new(method(:expect_call))
    end

    # Check that the expected calls to this mock were made, and
    # raise a Test::Unit::AssertionFailed exception otherwise.  This
    # method will be called automatically if you use the methods provided
    # by TestCaseHelpers
    def verify
      missing_expectations = @expectations - @satisfied_expectations
      if missing_expectations.any?
        raise AssertionFailedError.new("Expected #{missing_expectations[0]} did not happen")
      end
    end

    def use &block
      block.call(proxy)
      verify
    end

    private

    def create_proxy
      @proxy = Object.new
      @stubs = @proxy.instance_eval '@stubs = {}'
    end

    def stub_for(method_name)
      mock_method = @stubs[method_name]
      unless mock_method
        mock_method = @stubs[method_name]= Response.new
        install_method_in_proxy(method_name)
      end
      mock_method
    end

    def stub_call(method_name, *argspec)
      stub_for(method_name).add_handler(CallMatcher.new(method_name, argspec))
    end

    def expect_call(method_name, *argspec)
      handler = CallMatcher.new(method_name, argspec) do |satisfied|
        if @satisfied_expectations.include?(satisfied)
          raise AssertionFailedError.new("Unexpected extra call to #{method_name}")
        end
        @satisfied_expectations << satisfied
      end
      @expectations << stub_for(method_name).add_handler(handler)
      handler
    end

    def install_method_in_proxy(method_name)
      @proxy.instance_eval(<<-EOF)
        def #{method_name.to_s}(*args, &block)
          args << block if block
          @stubs[:#{method_name}].call(*args)
        end
      EOF
    end
  end

  ################################################################################
  private
  ################################################################################

  class CallMatcher # :nodoc:

    def initialize(method_name, argspec, &listener)
      @method_name = method_name
      @argspec = argspec
      @response = lambda { }
      @listener = listener
    end

    def ===(args)
      return false if args.size > @argspec.size
      @argspec.zip(args).each do |expected, actual|
        return false unless expected === actual
      end
      true
    end

    def call
      @listener.call(self) if @listener
      @response.call
    end

    def to_s
      "call to #{@method_name} with args #{@argspec.inspect}"
    end

    def as(&block)
      @response = block
    end
  end

  ################################################################################

  class Response # :nodoc:
    include ::Test::Unit

    def initialize
      @handlers = []
    end

    def add_handler(handler)
      @handlers << handler; handler
    end

    def call(*args, &block)
      args << block if block
      @handlers.each do |handler|
        return handler.call if handler === args
      end
      raise AssertionFailedError.new("no match for arguments: #{args.inspect}")
    end
  end

  class CallRecorder # :nodoc:
    def initialize(on_call)
      @on_call = on_call
    end
    public_instance_methods.each do |meth|
      undef_method(meth) unless %w(__id__ __send__ method_missing).include?(meth)
    end
    def method_missing(meth, *args)
      @on_call.call(meth, *args)
    end
  end

  # Include this module in your Test::Unit::TestCase in order to more conveniently
  # use and verify mocks.
  module TestCaseHelpers

    # Create a new mock and remember it so that it can be automatically
    # verified when the test case completes
    def new_mock
      @mocks ||= []
      @mocks << (mock = Mock.new)
      mock
    end

    def teardown # :nodoc:
      verify_all_mocks
    end

    # Verify all mocks that were created using #new_mock.
    #
    # Usually you will not
    # need to call this method yourself -- it is called automatically unless
    # you override #teardown for your own purposes
    def verify_all_mocks
      return unless instance_variables.include?("@mocks")
      @mocks.each do |mock|
        mock.verify
      end
    end

  end

end
