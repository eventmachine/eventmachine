module EventMachine
  # Utility method for coercing arguments to an object that responds to :call.
  # Accepts an object and a method name to send to, or a block, or an object
  # that responds to :call.
  #
  # @example EventMachine.Callback used with a block. Returns that block.
  #
  #  cb = EventMachine.Callback do |msg|
  #    puts(msg)
  #  end
  #  # returned object is a callable
  #  cb.call('hello world')
  #
  #
  # @example EventMachine.Callback used with an object (to be more specific, class object) and a method name, returns a callable
  #
  #  cb = EventMachine.Callback(Object, :puts)
  #  # returned object is a callable that delegates to Kernel#puts (in this case Object.puts)
  #  cb.call('hello world')
  #
  #
  # @example EventMachine.Callback used with an object that is callable. Returns the argument.
  #
  #  cb = EventMachine.Callback(proc{ |msg| puts(msg) })
  #  # returned object is a callable
  #  cb.call('hello world')
  #
  #
  # @overload Callback(object, method)
  #   Wraps `method` invocation on `object` into a callable that proxies all the arguments to that method
  #   @param [Object] Object to invoke method on
  #   @param [Symbol] Method name
  #   @return [<#call>] A callable that takes any number of arguments and invokes method on object with those arguments
  #
  # @overload Callback(object)
  #   Returns callable object as is, without any coercion
  #   @param [<#call>] A callable
  #   @return [<#call>] Its argument
  #
  # @overload Callback(&block)
  #   Returns block passed to it without any coercion
  #   @return [<#call>] Block passed to this method
  #
  # @raise [ArgumentError] When argument isn't callable, method name is missing or when invoked without arguments and block isn't given
  #
  # @return [<#call>]
  def self.Callback(object = nil, method = nil, &blk)
    if object && method
      lambda { |*args| object.__send__ method, *args }
    else
      if object.respond_to? :call
        object
      else
        blk || raise(ArgumentError)
      end # if
    end # if
  end # self.Callback
end # EventMachine
