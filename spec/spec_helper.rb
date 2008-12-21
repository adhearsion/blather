require File.join(File.dirname(__FILE__), *%w[.. lib blather])
require 'rubygems'
require 'minitest/spec'
require 'mocha'

module MiniTest
  if MINI_DIR =~ %r{^./}
    require 'pathname'
    path = Pathname.new(MINI_DIR).realpath
#    remove_const 'MINI_DIR'
#    const_set 'MINI_DIR', path.to_s
  end

  module Assertions
    def assert_change(obj, method, args = {}, msg = nil)
      msg ||= proc {
        m = "Expected #{obj}.#{method} to change"
        m << " by #{mu_pp args[:by]}" if args[:by]
        m << (args[:from] ? " from #{mu_pp args[:from]}" : '') + " to #{mu_pp args[:to]}" if args[:to]
        m
      }.call

      init_val = eval(obj).__send__(method)
      yield
      new_val = eval(obj).__send__(method)

      assert_equal(args[:by], (new_val - init_val), msg) if args[:by]
      assert_equal([args[:from], args[:to]], [(init_val if args[:from]), new_val], msg) if args[:to]
      refute_equal(init_val, new_val, msg) if args.empty?
    end
  end
end

class Object
  def must_change *args, &block
    return MiniTest::Spec.current.assert_change(*args, &self)
  end
end

require 'mocha/expectation_error'

include Blather
include MiniTest

LOG.level = Logger::INFO

Unit.autorun
