module Flipper
  module Toggles
    class Value < Toggle
      def enable(thing)
        super
        adapter.write adapter_key, thing.value
        true
      end

      def disable(thing)
        super
        adapter.delete adapter_key
        true
      end

      def value
        adapter.read adapter_key
      end

      def enabled?
        !value.nil? && value.to_i > 0
      end
    end
  end
end
