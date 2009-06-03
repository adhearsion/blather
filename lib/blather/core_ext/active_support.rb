require File.join(File.dirname(__FILE__), 'active_support', 'inheritable_attributes')

class Object # :nodoc:
  def duplicable?; true; end
  def blank?; respond_to?(:empty?) ? empty? : !self; end
  def present?; !blank?; end
end

class Array #:nodoc:
  alias_method :blank?, :empty?
  def extract_options!; last.is_a?(::Hash) ? pop : {}; end
end

class Hash #:nodoc:
  alias_method :blank?, :empty?
end

class String #:nodoc:
  def blank?; self !~ /\S/; end
end

class NilClass #:nodoc:
  def duplicable?; false; end
  def blank?; true; end
end

class FalseClass #:nodoc:
  def duplicable?; false; end
  def blank?; true; end
end

class TrueClass #:nodoc:
  def duplicable?; false; end
  def blank?; false; end
end

class Symbol #:nodoc:
  def duplicable?; false; end
end

class Numeric #:nodoc:
  def duplicable?; false; end
  def blank?; false; end
end
