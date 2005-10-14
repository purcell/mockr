# = RMock - A Mock Object library inspired by JMock
#
# Copyright (c) 2005 Steve Purcell
# Licenced under the same terms as Ruby itself
#
# == Introduction
#
# An instance of RMock::Mock can be programmed with responses to
# methods calls expected during the course of a unit test.  At the
# end of the test, the instance can verify whether its expectations
# were met, signalling a test failure if they were not.
#
# Mocks distinguish between 'expected' method calls, which trigger
# test failures if they are not made, and 'stub' method calls, which
# are not verified.  'Expected' calls are typically those considered
# critical to the proper use of the mocked class, and 'stub' calls are
# those considered more flexible in their use.
#
# == Example
#
# We are testing a controller for the air pump in a new automatic
# bicycle tyre inflator:
#
# class PumpTest < Test::Unit::TestCase
#
#   def test_inflates_in_5psi_increments
#     gauge_mock = RMock::Mock.new
#     gauge_mock.expects.pressure?.as { 95 }
#     end
#
#     gauge_mock.use do |gauge|
#       pump = Pump.new(pressure_gauge)
#       pump.inflate_to(110)
#     end
#   end
#


require 'test/unit'

module RMock

  ################################################################################

  class Mock
    include ::Test::Unit

    attr_reader :proxy

    def initialize &block
      @expectations = []
      @satisfied_expectations = []
      create_proxy
      block.call(self) if block
    end

    def stubs(&block)
      CallCapturer.new(method(:stub_call))
    end

    def expects(&block)
      CallCapturer.new(method(:expect_call))
    end

    def stub_call(method_name, *argspec)
      stub_for(method_name).add_handler(Matcher.new(argspec))
    end

    def expect_call(method_name, *argspec)
      handler = Matcher.new(argspec) do |satisfied|
        if @satisfied_expectations.include?(satisfied)
          raise AssertionFailedError.new("Unexpected extra call to #{method_name}")
        end
        @satisfied_expectations << satisfied
      end
      @expectations << stub_for(method_name).add_handler(handler)
      handler
    end

    def verify
      missing_expectations = @expectations - @satisfied_expectations
      if missing_expectations.any?
        raise AssertionFailedError.new('Expected #{missing_expectations[0]} did not happen')
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
      @stubs[method_name] ||= MockMethod.new(@proxy, method_name)
    end
  end

  ################################################################################
  private
  ################################################################################

  class Matcher
    def initialize(argspec, response=nil, &listener)
      @argspec = argspec
      @response = response
      @response ||= lambda { }
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
      @argspec.inspect
    end

    def as(&block)
      @response = block
    end
  end

  ################################################################################

  class MockMethod
    include ::Test::Unit

    def initialize(proxy, method_name)
      proxy.instance_eval <<-EOF
        def #{method_name.to_s}(*args, &block)
          args << block if block
          @stubs[:#{method_name}].call(*args)
        end
      EOF
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

  class CallCapturer
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

end
