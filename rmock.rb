require 'test/unit'

module RMock

  class Mock
    include ::Test::Unit

    attr_reader :proxy

    def initialize &block
      @expectations = []
      @satisfied_expectations = []
      create_proxy
      block.call(self) if block
    end

    def stub(method_name, *argspec)
      stub_for(method_name).add_handler(Matcher.new(argspec))
    end

    def expect(method_name, *argspec)
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

  private

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

    def will(&block)
      @response = block
    end
  end

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

end
