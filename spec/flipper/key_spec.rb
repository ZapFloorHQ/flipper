require 'helper'
require 'flipper/key'

describe Flipper::Key do
  subject { described_class.new(:foo, :bar) }

  it "initializes with prefix and suffix" do
    key = described_class.new(:foo, :bar)
    key.should be_instance_of(described_class)
  end

  describe "#to_s" do
    it "returns prefix and suffix joined by separator" do
      subject.to_s.should eq("foo#{subject.separator}bar")
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      subject.inspect.should eq("#<Flipper::Key:#{subject.object_id} prefix=:foo, suffix=:bar>")
    end
  end
end
