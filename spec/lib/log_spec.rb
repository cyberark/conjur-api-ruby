require 'spec_helper'
require 'io_helper'
require 'tempfile'

describe Conjur do
  describe '::log=' do
    let(:log) { double 'log' }
    it "creates the log with given type and makes it available" do
      Conjur.stub(:create_log).with(:param).and_return log
      Conjur::log = :param
      Conjur::log.should == log
    end
    after { Conjur.class_variable_set :@@log, nil }
  end

  describe '::create_log' do
    let(:log) { Conjur::create_log param }
    context "with 'stdout'" do
      let(:param) { 'stdout' }
      it "creates something which writes to STDOUT" do
        STDOUT.grab { log << "foo" }.should == 'foo'
      end
    end

    context "with 'stderr'" do
      let(:param) { 'stderr' }
      it "creates something which writes to STDERR" do
        STDERR.grab { log << "foo" }.should == 'foo'
      end
    end

    context "with a filename" do
      let(:tempfile) { Tempfile.new 'spec' }
      let(:param) { tempfile.path }
      it "creates something which writes to the file" do
        log << "foo"
        tempfile.read.should == "foo"
      end
    end
  end
end
