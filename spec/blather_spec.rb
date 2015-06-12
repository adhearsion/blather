require 'spec_helper'

describe Blather do

  describe "while accessing to Logger object" do
    it "should return a Logger instance" do
      Blather.logger.should be_instance_of Logger
    end
  end

  describe "while using the log method" do
    after do
      Blather.default_log_level = :debug
    end

    it "should forward to debug by default" do
      Blather.logger.expects(:debug).with("foo bar").once
      Blather.log "foo bar"
    end

    %w<debug info error fatal>.each do |val|
      it "should forward to #{val} if configured that default level" do
        Blather.logger.expects(val.to_sym).with("foo bar").once
        Blather.default_log_level = val.to_sym
        Blather.log "foo bar"
      end
    end

  end
end
