require File.join(File.dirname(__FILE__), *%w[.. lib blather])
require 'rubygems'
require 'minitest/spec'
require 'mocha'
require 'mocha/expectation_error'

module MiniTest
  require 'pathname' if MINI_DIR =~ %r{^./}

  module Assertions
    def assert_change(stmt, args = {}, msg = nil)
      msg ||= proc {
        m = "Expected #{stmt} to change"
        m << " by #{mu_pp args[:by]}" if args[:by]
        m << (args[:from] ? " from #{mu_pp args[:from]}" : '') + " to #{mu_pp args[:to]}" if args[:to]
        m
      }.call

      init_val = eval(stmt)
      yield
      new_val = eval(stmt)

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

include Blather
include MiniTest

Unit.autorun
