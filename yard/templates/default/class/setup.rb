def init
  super
  sections.place(:handlers).after(:box_info)
end

def handlers
  @handler_stack = object.inheritance_tree.map { |o| o.tag(:handler).name if (o.respond_to?(:tag) && o.tag(:handler)) }.compact
  return if @handler_stack.empty?
  erb(:handlers)
end
