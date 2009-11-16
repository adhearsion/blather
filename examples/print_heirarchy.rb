require 'blather'

class Object
  begin
    ObjectSpace.each_object(Class.new) {}

    # Exclude this class unless it's a subclass of our supers and is defined.
    # We check defined? in case we find a removed class that has yet to be
    # garbage collected. This also fails for anonymous classes -- please
    # submit a patch if you have a workaround.
    def subclasses_of(*superclasses)
      subclasses = []

      superclasses.each do |sup|
        ObjectSpace.each_object(class << sup; self; end) do |k|
          if k != sup && (k.name.blank? || eval("defined?(::#{k}) && ::#{k}.object_id == k.object_id"))
            subclasses << k
          end
        end
      end

      subclasses
    end
  rescue RuntimeError
    # JRuby and any implementations which cannot handle the objectspace traversal
    # above fall back to this implementation
    def subclasses_of(*superclasses)
      subclasses = []

      superclasses.each do |sup|
        ObjectSpace.each_object(Class) do |k|
          if superclasses.any? { |superclass| k < superclass } &&
            (k.name.blank? || eval("defined?(::#{k}) && ::#{k}.object_id == k.object_id"))
            subclasses << k
          end
        end
        subclasses.uniq!
      end
      subclasses
    end
  end
end

class Hash
  def deep_merge(second)
    # From: http://www.ruby-forum.com/topic/142809
    # Author: Stefan Rusterholz
    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end

handlers = {}
(Object.subclasses_of(Blather::Stanza) + Object.subclasses_of(Blather::BlatherError)).each do |klass|
  handlers = handlers.deep_merge klass.handler_heirarchy.inject('klass' => klass.to_s.gsub('Blather::', '')) { |h,k| {k.to_s => h} }
end

level = 0
runner = proc do |k,v|
  next if k == 'klass'

  str = ''
  if level > 0
    (level - 1).times { str << '|  ' }
    str << '|- '
  end

  puts str+k
  if Hash === v
    level += 1
    v.sort.each &runner
    level -= 1
  end
end

handlers.sort.each &runner
