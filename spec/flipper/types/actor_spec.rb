require 'helper'
require 'flipper/types/actor'

describe Flipper::Types::Actor do
  subject {
    thing = thing_class.new('2')
    described_class.new(thing)
  }

  let(:thing_class) {
    Class.new {
      attr_reader :flipper_id

      def initialize(flipper_id)
        @flipper_id = flipper_id
      end

      def admin?
        true
      end
    }
  }

  describe ".wrappable?" do
    it "returns true if actor" do
      thing = thing_class.new('1')
      actor = described_class.new(thing)
      described_class.wrappable?(actor).should eq(true)
    end

    it "returns true if responds to id" do
      thing = thing_class.new(10)
      described_class.wrappable?(thing).should eq(true)
    end
  end

  describe ".wrap" do
    context "for actor" do
      it "returns actor" do
        actor = described_class.wrap(subject)
        actor.should be_instance_of(described_class)
        actor.should be(subject)
      end
    end

    context "for other thing" do
      it "returns actor" do
        thing = thing_class.new('1')
        actor = described_class.wrap(thing)
        actor.should be_instance_of(described_class)
      end
    end
  end

  it "initializes with thing that responds to id" do
    thing = thing_class.new('1')
    actor = described_class.new(thing)
    actor.value.should eq('1')
  end

  it "raises error when initialized with nil" do
    expect {
      described_class.new(nil)
    }.to raise_error(ArgumentError)
  end

  it "raises error when initalized with non-wrappable object" do
    unwrappable_thing = Struct.new(:id).new(1)
    expect {
      described_class.new(unwrappable_thing)
    }.to raise_error(ArgumentError, "#{unwrappable_thing.inspect} must respond to flipper_id, but does not")
  end

  it "converts id to string" do
    thing = thing_class.new(2)
    actor = described_class.new(thing)
    actor.value.should eq('2')
  end

  it "provides accessor to original thing" do
    thing = thing_class.new(2)
    actor = described_class.new(thing)
    actor.thing.should thing
  end

  it "proxies everything to thing" do
    thing = thing_class.new(10)
    actor = described_class.new(thing)
    actor.admin?.should eq(true)
  end

  describe "#respond_to?" do
    it "returns true if responds to method" do
      thing = thing_class.new('1')
      actor = described_class.new(thing)
      actor.respond_to?(:value).should eq(true)
    end

    it "returns true if thing responds to method" do
      thing = thing_class.new(10)
      actor = described_class.new(thing)
      actor.respond_to?(:admin?).should eq(true)
    end

    it "returns false if does not respond to method and thing does not respond to method" do
      thing = thing_class.new(10)
      actor = described_class.new(thing)
      actor.respond_to?(:frankenstein).should eq(false)
    end
  end
end
