require_relative "../helper"

# Not worth trying to test on old Rails versions
return unless Rails::VERSION::MAJOR >= 7

require "capybara/cuprite"
require "flipper"
require "flipper/test_help"

require 'action_dispatch/system_testing/server'
ActionDispatch::SystemTesting::Server.silence_puma = true

class TestApp < Rails::Application
  config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
  config.eager_load = false
  config.logger = ActiveSupport::Logger.new(StringIO.new)
  routes.append do
    root to: "features#index"
  end
end

TestApp.initialize!

class FeaturesController < ActionController::Base
  def index
    render json: Flipper.enabled?(:test) ? "Enabled" : "Disabled"
  end
end

class TestHelpTest < ActionDispatch::SystemTestCase
  # Any driver that runs the app in a separate thread will test what we want here.
  driven_by :cuprite, options: { process_timeout: 30 }

  # Ensure this test uses this app instance
  setup { Rails.application = TestApp.instance }

  test "configures a shared adapter between tests and app" do
    Flipper.disable(:test)
    visit "/"
    assert_selector "*", text: "Disabled"

    Flipper.enable(:test)
    visit "/"
    assert_selector "*", text: "Enabled"
  end
end
