require 'flipper/adapter'
require 'flipper/errors'
require 'flipper/type'
require 'flipper/toggle'
require 'flipper/gate'
require 'flipper/instrumenters/noop'

module Flipper
  class Feature
    # Private: The name of instrumentation events.
    InstrumentationName = "feature_operation.#{InstrumentationNamespace}"

    # Internal: The name of the feature.
    attr_reader :name

    # Private: The adapter this feature should use.
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumenter

    # Internal: Initializes a new feature instance.
    #
    # name - The Symbol or String name of the feature.
    # adapter - The adapter that will be used to store details about this feature.
    #
    # options - The Hash of options.
    #           :instrumenter - What to use to instrument all the things.
    #
    def initialize(name, adapter, options = {})
      @name = name
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      @adapter = Adapter.wrap(adapter, :instrumenter => @instrumenter)
    end

    # Public: Enable this feature for something.
    #
    # Returns the result of Flipper::Gate#enable.
    def enable(thing = Types::Boolean.new)
      instrument(:enable, thing) { |payload|
        gate = gate_for(thing)
        payload[:gate_name] = gate.name
        gate.enable(thing)
      }
    end

    # Public: Disable this feature for something.
    #
    # Returns the result of Flipper::Gate#disable.
    def disable(thing = Types::Boolean.new)
      instrument(:disable, thing) { |payload|
        gate = gate_for(thing)
        payload[:gate_name] = gate.name
        gate.disable(thing)
      }
    end

    # Public: Check if a feature is enabled for a thing.
    #
    # Returns true if enabled, false if not.
    def enabled?(thing = nil)
      instrument(:enabled?, thing) { |payload|
        gate = gates.detect { |gate| gate.open?(thing) }

        if gate.nil?
          false
        else
          payload[:gate_name] = gate.name
          true
        end
      }
    end

    # Internal: Gates to check to see if feature is enabled/disabled
    #
    # Returns an array of gates
    def gates
      @gates ||= [
        Gates::Boolean.new(self, :instrumenter => @instrumenter),
        Gates::Group.new(self, :instrumenter => @instrumenter),
        Gates::Actor.new(self, :instrumenter => @instrumenter),
        Gates::PercentageOfActors.new(self, :instrumenter => @instrumenter),
        Gates::PercentageOfRandom.new(self, :instrumenter => @instrumenter),
      ]
    end

    # Internal: Find the gate that protects a thing.
    #
    # thing - The object for which you would like to find a gate
    #
    # Returns a Flipper::Gate.
    # Raises Flipper::GateNotFound if no gate found for thing
    def gate_for(thing)
      gates.detect { |gate| gate.protects?(thing) } ||
        raise(GateNotFound.new(thing))
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "state=#{state.inspect}",
        "adapter=#{adapter.name.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    # Public
    def state
      if boolean_gate.enabled?
        :on
      elsif conditional_gates.any?
        :conditional
      else
        :off
      end
    end

    # Public
    def description
      if boolean_gate.enabled?
        boolean_gate.description.capitalize
      elsif conditional_gates.any?
        fragments = conditional_gates.map(&:description)
        "Enabled for #{fragments.join(', ')}"
      else
        boolean_gate.description.capitalize
      end
    end

    # Private
    def boolean_gate
      @boolean_gate ||= gates.detect { |gate| gate.name == :boolean }
    end

    # Private
    def non_boolean_gates
      @non_boolean_gates ||= gates - [boolean_gate]
    end

    # Private
    def conditional_gates
      @conditional_gates ||= non_boolean_gates.select { |gate| gate.enabled? }
    end

    # Private
    def instrument(operation, thing)
      payload = {
        :feature_name => name,
        :operation => operation,
        :thing => thing,
      }

      @instrumenter.instrument(InstrumentationName, payload) {
        payload[:result] = yield(payload) if block_given?
      }
    end
  end
end
