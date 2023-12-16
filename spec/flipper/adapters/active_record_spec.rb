require 'flipper/adapters/active_record'
require 'active_support/core_ext/kernel'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false
ActiveRecord::Tasks::DatabaseTasks.root = File.dirname(__FILE__)

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    # Eval migration template so we can run migration against each database
    migration = ERB.new(File.read(File.join(File.dirname(__FILE__), '../../../lib/generators/flipper/templates/migration.erb')))
    migration_version = "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    eval migration.result(binding) # defines CreateFlipperTables
  end

  [
    {
      adapter: "sqlite3",
      database: ":memory:"
    },

    {
      adapter: "mysql2",
      encoding: "utf8mb4",
      username: ENV["MYSQL_USER"] || "root",
      password: ENV["MYSQL_PASSWORD"] || "",
      database: ENV["MYSQL_DATABASE"] || "flipper_test",
      port: ENV["DB_PORT"] || 3306
    },

    {
      adapter: "postgresql",
      encoding: "unicode",
      host: "127.0.0.1",
      username: ENV["POSTGRES_USER"] || "",
      password: ENV["POSTGRES_PASSWORD"] || "",
      database: ENV["POSTGRES_DATABASE"] || "flipper_test",
    }
  ].each do |config|
    config = config.with_indifferent_access

    context "with #{config[:adapter]}" do
      before(:all) do
        ActiveRecord::Tasks::DatabaseTasks.create(config)
      end

      before(:each) do
        skip_on_error(ActiveRecord::ConnectionNotEstablished, "#{config[:adapter]} not available") do
          ActiveRecord::Base.establish_connection(config)
          CreateFlipperTables.migrate(:up)
        end
      end

      after(:each) do
        ActiveRecord::Tasks::DatabaseTasks.purge(config)
        ActiveRecord::Base.connection.close
      end

      after(:all) do
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
      end

      it_should_behave_like 'a flipper adapter'

      it "works when table doesn't exist" do
        CreateFlipperTables.migrate(:down)

        Flipper.configuration = nil
        Flipper.instance = nil

        silence_warnings { load 'flipper/adapters/active_record.rb' }
        expect { Flipper::Adapters::ActiveRecord.new }.not_to raise_error
      end

      it "should load actor ids fine" do
        flipper.enable_percentage_of_time(:foo, 1)

        Flipper::Adapters::ActiveRecord::Gate.create!(
          feature_key: "foo",
          key: "actors",
          value: "Organization;4",
        )

        flipper = Flipper.new(subject)
        flipper.preload([:foo])
      end

      context 'requiring "flipper-active_record"' do
        before do
          Flipper.configuration = nil
          Flipper.instance = nil

          silence_warnings { load 'flipper/adapters/active_record.rb' }
        end

        it 'configures itself' do
          expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::ActiveRecord)
        end
      end

      context "ActiveRecord connection_pool" do
        before do
          ActiveRecord::Base.clear_active_connections!
        end

        context "#features" do
          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.features
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.features
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end

        context "#get_all" do
          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.get_all
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.get_all
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end

        context "#add / #remove / #clear" do
          let(:feature) { Flipper::Feature.new(:search, subject) }

          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.add(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.remove(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.clear(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.add(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.remove(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.clear(feature)
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end

        context "#get_multi" do
          let(:feature) { Flipper::Feature.new(:search, subject) }

          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.get_multi([feature])
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.get_multi([feature])
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end

        context "#enable/#disable boolean" do
          let(:feature) { Flipper::Feature.new(:search, subject) }
          let(:gate) { feature.gate(:boolean)}

          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.enable(feature, gate, gate.wrap(true))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.disable(feature, gate, gate.wrap(false))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.enable(feature, gate, gate.wrap(true))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.disable(feature, gate, gate.wrap(false))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end

        context "#enable/#disable set" do
          let(:feature) { Flipper::Feature.new(:search, subject) }
          let(:gate) { feature.gate(:group) }

          it "does not hold onto connections" do
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.enable(feature, gate, gate.wrap(:admin))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
            subject.disable(feature, gate, gate.wrap(:admin))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(false)
          end

          it "does not release previously held connection" do
            ActiveRecord::Base.connection # establish a new connection
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.enable(feature, gate, gate.wrap(:admin))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
            subject.disable(feature, gate, gate.wrap(:admin))
            expect(ActiveRecord::Base.connection_handler.active_connections?).to be(true)
          end
        end
      end
    end
  end
end
