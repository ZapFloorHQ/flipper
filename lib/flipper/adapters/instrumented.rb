require 'flipper/adapters/decorator'
require 'flipper/instrumenters/noop'

module Flipper
  module Adapters
    class Instrumented < Decorator
      # Private: The name of instrumentation events.
      InstrumentationName = "adapter_operation.#{InstrumentationNamespace}"

      # Private: What is used to instrument all the things.
      attr_reader :instrumenter

      # Internal: Initializes a new adapter instance.
      #
      # adapter - Vanilla adapter instance to wrap.
      #
      # options - The Hash of options.
      #           :instrumenter - What to use to instrument all the things.
      #
      def initialize(adapter, options = {})
        super(adapter)
        @name = :instrumented
        @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      end

      def get(feature)
        payload = {
          :operation => :get,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public: Enable feature gate for thing.
      def enable(feature, gate, thing)
        payload = {
          :operation => :enable,
          :adapter_name => name,
          :feature_name => feature.name,
          :gate_name => gate.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public: Disable feature gate for thing.
      def disable(feature, gate, thing)
        payload = {
          :operation => :disable,
          :adapter_name => name,
          :feature_name => feature.name,
          :gate_name => gate.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public: Returns all the features that the adapter knows of.
      def features
        payload = {
          :operation => :features,
          :adapter_name => name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Internal: Adds a known feature to the set of features.
      def add(feature)
        payload = {
          :operation => :add,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end
    end
  end
end
