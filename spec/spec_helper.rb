require File.join(File.dirname(__FILE__), *%w[.. lib blather])
require 'rubygems'
require 'minitest/spec'
require 'minitest/mock'

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

  class Mock
    def verify_calls
      @expected_calls.each_key do |name|
        expected = @expected_calls[name]
        msg = "expected #{name}, #{expected.inspect}"
        raise MockExpectationError, msg unless
          @actual_calls.has_key? name
      end
      true
    end
  end
end

class Object
  def must_change *args, &block
    return MiniTest::Spec.current.assert_change(*args, &self)     if Proc === self
    return MiniTest::Spec.current.assert_change(args.first, self) if args.size == 1
    return MiniTest::Spec.current.assert_change(self, *args)
  end
end

include Blather
include MiniTest

def stream(reset = false)
  @stream = (!@stream || reset) ? Mock.new.expect(:send_data, nil, [1]) : @stream
end

def stanza(reset = false)
  @stanza = if (!@stanza || reset)
    items = []; 4.times { |n| items << JID.new("n@d/#{n}r") }
    Mock.new.expect(:items, items)
  else
    @stanza
  end
end

def roster(reset = false)
  @roster ||= (!@roster || reset) ? Roster.new(stream, stanza) : @roster
end

def reset_helpers
  stanza true
  stream true
  roster true
end

Unit.autorun
