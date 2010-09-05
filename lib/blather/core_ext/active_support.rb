require File.join(File.dirname(__FILE__), 'active_support', 'inheritable_attributes')

class Object  # @private
  def duplicable?; true; end
  def blank?; respond_to?(:empty?) ? empty? : !self; end
  def present?; !blank?; end
end

class Array  # @private
  alias_method :blank?, :empty?
  def extract_options!; last.is_a?(::Hash) ? pop : {}; end
end

class Hash  # @private
  alias_method :blank?, :empty?
end

class String  # @private
  def blank?; self !~ /\S/; end
end

class NilClass  # @private
  def duplicable?; false; end
  def blank?; true; end
end

class FalseClass  # @private
  def duplicable?; false; end
  def blank?; true; end
end

class TrueClass  # @private
  def duplicable?; false; end
  def blank?; false; end
end

class Symbol  # @private
  def duplicable?; false; end
  def to_proc; proc { |obj, *args| obj.send(self, *args) }; end
end

class Numeric  # @private
  def duplicable?; false; end
  def blank?; false; end
end
