$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'blather'
require 'minitest/spec'
require 'mocha'
require 'mocha/expectation_error'

MiniTest::Unit.autorun

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

      init_val = eval stmt
      yield
      new_val = eval stmt

      assert_equal(args[:by], (new_val - init_val), msg) if args[:by]
      assert_equal([args[:from], args[:to]], [(init_val if args[:from]), new_val], msg) if args[:to]
      refute_equal(init_val, new_val, msg) if args.empty?
    end

    def assert_nothing_raised(*args)
      self._assertions += 1
      msg = Module === args.last ? nil : args.pop
      begin
        line = __LINE__; yield
      rescue Exception => e
        bt = e.backtrace
        as = e.instance_of?(MiniTest::Assertion)
        if as
          ans = /\A#{Regexp.quote(__FILE__)}:#{line}:in /o
          bt.reject! {|ln| ans =~ ln}
        end
        if ((args.empty? && !as) ||
            args.any? {|a| a.instance_of?(Module) ? e.is_a?(a) : e.class == a })
          msg = message(msg) { "Exception raised:\n<#{mu_pp(e)}>" }
          raise MiniTest::Assertion, msg.call, bt
        else
          raise
        end
      end
      nil
    end
  end
end

class Object
  def must_change *args, &block
    return MiniTest::Spec.current.assert_change(*args, &self)
  end
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml
end
