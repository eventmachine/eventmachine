module EventMachine
  # Utility method for coercing arguments to an object that responds to #call
  # Accepts an object and a method name to send to, or a block, or an object
  # that responds to call.
  def self.Callback(object = nil, method = nil, &blk)
    if object && method
      lambda { |*args| object.send method, *args }
    else
      if object.respond_to? :call
        object
      else 
        blk || raise(ArgumentError)
      end
    end
  end
end