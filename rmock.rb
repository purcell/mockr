
module RMock

  class Mock
    include ::Test::Unit

    attr_reader :proxy

    def initialize &block
      @proxy = Object.new
      @stubs = {}
      @expectations = []
      @satisfied_expectations = []
      block.call(self) if block
    end

    def stub(method_name, *argspec)
      ensure_stub(method_name).add_handler(MethodHandler.new(argspec))
    end

    def expect(method_name, *argspec)
      handler = MethodHandler.new(argspec) do |satisfied|
        @satisfied_expectations << satisfied
      end
      @expectations << ensure_stub(method_name).add_handler(handler)
      handler
    end

    def verify
      missing_expectations = @expectations - @satisfied_expectations
      if missing_expectations.any?
        raise AssertionFailedError.new('Expected #{missing_expectations[0]} did not happen')
      end
    end

    private

    def ensure_stub(method_name)
      return @stubs[method_name] if @stubs[method_name]
      @stubs[method_name] = stub_method = StubMethod.new
      class << @proxy; self end.send(:define_method, method_name) do |*args|
        stub_method.call(*args)
      end
      stub_method
    end

  end

  private

  class MethodHandler
    def initialize(argspec, &listener)
      @argspec = argspec
      @to_return = nil
      @listener = listener
    end

    def ===(args)
      @argspec === args
    end

    def call
      @listener.call(self) if @listener
      @to_return
    end

    def to_s
      @argspec.inspect
    end

    def will_return(result)
      @to_return = result
    end
  end

  class StubMethod
    include ::Test::Unit

    def initialize
      @handlers = []
    end

    def add_handler(handler)
      @handlers << handler; handler
    end

    def call(*args)
      @handlers.each do |handler|
        return handler.call if handler === args
      end
      raise AssertionFailedError.new("no match for arguments: #{args.inspect}")
    end
  end

end