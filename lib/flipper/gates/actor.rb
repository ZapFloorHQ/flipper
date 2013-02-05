module Flipper
  module Gates
    class Actor < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :actor
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :actors
      end

      # Internal: The toggle class used to enable/disable the gate for a thing.
      def toggle_class
        Toggles::Set
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing)
        instrument(:open?, thing) { |payload|
          if thing.nil?
            false
          else
            if Types::Actor.wrappable?(thing)
              actor = Types::Actor.wrap(thing)
              enabled_actor_ids = toggle.value
              enabled_actor_ids.include?(actor.value)
            else
              false
            end
          end
        }
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end

      def enable(thing)
        super Types::Actor.wrap(thing)
      end

      def disable(thing)
        super Types::Actor.wrap(thing)
      end

      def description
        if enabled?
          "actors (#{toggle.value.to_a.sort.join(', ')})"
        else
          'disabled'
        end
      end
    end
  end
end
