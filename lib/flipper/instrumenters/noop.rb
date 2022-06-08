module Flipper
  module Instrumenters
    class Noop
      def self.instrument(_name, payload = {})
        yield payload if block_given?
      end

      def self.subscribe(_name, _callback = nil, &_block)
        # noop
      end
    end
  end
end
