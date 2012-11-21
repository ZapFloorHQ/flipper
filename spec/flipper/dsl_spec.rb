require 'helper'
require 'flipper/dsl'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:admins_feature) { feature(:admins) }

  def feature(name)
    Flipper::Feature.new(name, adapter)
  end

  it "wraps adapter when initializing" do
    dsl = described_class.new(adapter)
    dsl.adapter.should be_instance_of(Flipper::Adapter)
    dsl.adapter.adapter.should eq(adapter)
  end

  describe "#enabled?" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "passes arguments to feature enabled check and returns result" do
      admins_feature.should_receive(:enabled?).with(:foo).and_return(true)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.enabled?(:stats, :foo).should be_true
    end
  end

  describe "#disabled?" do
    it "passes all args to enabled? and returns the opposite" do
      subject.should_receive(:enabled?).with(:stats, :foo).and_return(true)
      subject.disabled?(:stats, :foo).should be_false
    end
  end

  describe "#enable" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "calls enable for feature with arguments" do
      admins_feature.should_receive(:enable).with(:foo)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.enable :stats, :foo
    end
  end

  describe "#disable" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "calls disable for feature with arguments" do
      admins_feature.should_receive(:disable).with(:foo)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.disable :stats, :foo
    end
  end

  describe "#feature" do
    before do
      @result = subject.feature(:stats)
    end

    it "returns instance of feature with correct name and adapter" do
      @result.should be_instance_of(Flipper::Feature)
      @result.name.should eq(:stats)
      @result.adapter.should eq(subject.adapter)
    end

    it "memoizes the feature" do
      subject.feature(:stats).should equal(@result)
    end
  end

  describe "#[]" do
    before do
      @result = subject[:stats]
    end

    it "returns instance of feature with correct name and adapter" do
      @result.should be_instance_of(Flipper::Feature)
      @result.name.should eq(:stats)
      @result.adapter.should eq(subject.adapter)
    end

    it "memoizes the feature" do
      subject[:stats].should equal(@result)
    end
  end

  describe "#group" do
    context "for registered group" do
      before do
        @group = Flipper.register(:admins) { }
      end

      it "returns group" do
        subject.group(:admins).should eq(@group)
      end

      it "always returns same instance for same name" do
        subject.group(:admins).should equal(subject.group(:admins))
      end
    end

    context "for unregistered group" do
      it "returns nil" do
        subject.group(:admins).should be_nil
      end
    end
  end

  describe "#actor" do
    context "for something that responds to identifier" do
      it "returns actor instance with identifier set to id" do
        user = Struct.new(:identifier).new(45)
        actor = subject.actor(user)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq('45')
      end
    end

    context "for a number" do
      it "returns actor instance with identifer set to number" do
        actor = subject.actor(33)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq('33')
      end
    end

    context "for nil" do
      it "raises error" do
        expect {
          subject.actor(nil)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#random" do
    before do
      @result = subject.random(5)
    end

    it "returns percentage of random" do
      @result.should be_instance_of(Flipper::Types::PercentageOfRandom)
    end

    it "sets value" do
      @result.value.should eq(5)
    end

    it "is aliased to percentage_of_random" do
      @result.should eq(subject.percentage_of_random(@result.value))
    end
  end

  describe "#actors" do
    before do
      @result = subject.actors(17)
    end

    it "returns percentage of actors" do
      @result.should be_instance_of(Flipper::Types::PercentageOfActors)
    end

    it "sets value" do
      @result.value.should eq(17)
    end

    it "is aliased to percentage_of_actors" do
      @result.should eq(subject.percentage_of_actors(@result.value))
    end
  end

  describe "#features" do
    context "with no features enabled/disabled" do
      it "defaults to empty set" do
        subject.features.should eq(Set.new)
      end
    end

    context "with features enabled and disabled" do
      before do
        subject[:stats].enable
        subject[:cache].enable
        subject[:search].disable
      end

      it "returns set of feature instances" do
        subject.features.should be_instance_of(Set)
        subject.features.each do |feature|
          feature.should be_instance_of(Flipper::Feature)
        end
        subject.features.map(&:name).map(&:to_s).sort.should eq(['cache', 'search', 'stats'])
      end
    end
  end
end
