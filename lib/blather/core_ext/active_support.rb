require File.join(File.dirname(__FILE__), 'active_support', 'inheritable_attributes')

# @private
class Object
  def duplicable?; true; end
  def blank?; respond_to?(:empty?) ? empty? : !self; end
  def present?; !blank?; end
end

# @private
class Array
  alias_method :blank?, :empty?
  def extract_options!; last.is_a?(::Hash) ? pop : {}; end
end

# @private
class Hash
  alias_method :blank?, :empty?
end

# @private
class String
  def blank?; self !~ /\S/; end
end

# @private
class NilClass
  def duplicable?; false; end
  def blank?; true; end
end

# @private
class FalseClass
  def duplicable?; false; end
  def blank?; true; end
end

# @private
class TrueClass
  def duplicable?; false; end
  def blank?; false; end
end

# @private
class Symbol
  def duplicable?; false; end
end

# @private
class Numeric
  def duplicable?; false; end
  def blank?; false; end
end
