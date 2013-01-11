module Flipper
  module Gates
    class PercentageOfRandom < Gate
      Key = :perc_time

      def name
        :percentage_of_random
      end

      def type_key
        Key
      end

      def open?(thing)
        instrument(:open, thing) {
          percentage = toggle.value.to_i

          rand < (percentage / 100.0)
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfRandom)
      end
    end
  end
end
