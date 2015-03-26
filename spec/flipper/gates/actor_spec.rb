require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Actor do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:feature_name) { :search }

  subject {
    described_class.new(feature_name, :instrumenter => instrumenter)
  }

  describe "#description" do
    context "with actors in set" do
      it "returns text" do
        values = Set['bacon', 'ham']
        subject.description(values).should eq('actors ("bacon", "ham")')
      end
    end

    context "with no actors in set" do
      it "returns disabled" do
        subject.description(Set.new).should eq('disabled')
      end
    end
  end
end
