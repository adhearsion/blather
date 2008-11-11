module Blather

  class Callback
    include Comparable

    attr_accessor :priority

    def initialize(priority = 0, &callback)
      @priority = priority
      @callback = callback
    end

    def call(*args)
      @callback.call(*args)
    end

    # Favor higher numbers
    def <=>(o)
      self.priority <=> o.priority
    end

  end #Callback

end