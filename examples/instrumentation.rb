require File.expand_path('../example_setup', __FILE__)

require 'securerandom'
require 'active_support/notifications'

class FlipperSubscriber
  def call(*args)
    event = ActiveSupport::Notifications::Event.new(*args)
    puts event.inspect
  end

  ActiveSupport::Notifications.subscribe(/flipper/, new)
end

require 'flipper'
require 'flipper/adapters/memory'

# pick an adapter
adapter = Flipper::Adapters::Memory.new

# get a handy dsl instance
flipper = Flipper.new(adapter, :instrumentor => ActiveSupport::Notifications)

# grab a feature
search = flipper[:search]

perform = lambda do
  # check if that feature is enabled
  if search.enabled?
    puts 'Search away!'
  else
    puts 'No search for you!'
  end
end

perform.call
puts 'Enabling Search...'
search.enable
perform.call
