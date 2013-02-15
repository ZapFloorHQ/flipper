require 'helper'

describe Flipper do
  describe ".new" do
    it "returns new instance of dsl" do
      instance = Flipper.new(double('Adapter'))
      instance.should be_instance_of(Flipper::DSL)
    end
  end

  describe ".groups" do
    it "returns a registry instance" do
      Flipper.groups.should be_instance_of(Flipper::Registry)
    end
  end

  describe ".groups=" do
    it "sets groups registry" do
      registry = Flipper::Registry.new
      Flipper.groups = registry
      Flipper.instance_variable_get("@groups").should eq(registry)
    end
  end

  describe ".register" do
    it "adds a group to the group_registry" do
      registry = Flipper::Registry.new
      Flipper.groups = registry
      group = Flipper.register(:admins) { |actor| actor.admin? }
      registry.get(:admins).should eq(group)
    end

    it "adds a group to the group_registry for string name" do
      registry = Flipper::Registry.new
      Flipper.groups = registry
      group = Flipper.register('admins') { |actor| actor.admin? }
      registry.get(:admins).should eq(group)
    end

    it "raises exception if group already registered" do
      Flipper.register(:admins) { }

      expect {
        Flipper.register(:admins) { }
      }.to raise_error(Flipper::DuplicateGroup, "Group :admins has already been registered")
    end
  end

  describe ".unregister_groups" do
    it "clear group registry" do
      Flipper.groups.should_receive(:clear)
      Flipper.unregister_groups
    end
  end

  describe ".group" do
    context "for registered group" do
      before do
        @group = Flipper.register(:admins) { }
      end

      it "returns group" do
        Flipper.group(:admins).should eq(@group)
      end

      it "returns group with string key" do
        Flipper.group('admins').should eq(@group)
      end
    end

    context "for unregistered group" do
      it "raises group not registered error" do
        expect {
          Flipper.group(:cats)
        }.to raise_error(Flipper::GroupNotRegistered, 'Group :cats has not been registered')
      end
    end
  end
end
