module Bulldozer::Third
  module ClassUtils
    def self.metaclass(object)
      object.instance_eval do
        class << self; self; end
      end
    end

    # define_method defines a method for instances of a class.  This
    # defines a method on the object itself (same as def object.foo;
    # ...; end)
    def self.define_object_method(object, name, method=nil, &blk)
      code = method || blk
      meta = metaclass(object)
      meta.send(:define_method, name, code)
    end
  end
end
