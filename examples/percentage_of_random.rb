require File.expand_path('../example_setup', __FILE__)

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)
logging = flipper[:logging]

perform_test = lambda do |number|
  logging.enable flipper.random(number)

  total = 1_000
  enabled = []
  disabled = []

  enabled = (1..total).map { |n|
    logging.enabled? ? true : nil
  }.compact

  actual = (enabled.size / total.to_f * 100).round(2)

  # puts "#{enabled.size} / #{total}"
  puts "percentage: #{actual.to_s.rjust(6, ' ')} vs #{number.to_s.rjust(3, ' ')}"
end

puts "percentage: Actual vs Hoped For"

[1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100].each do |number|
  perform_test.call number
end
