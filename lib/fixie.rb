require 'fixie/version'
require 'active_support/core_ext'
require 'erb'
require 'sequel'
require 'yaml'
require 'zlib'

module Fixie
  MAX_ID = 2 ** 30 - 1

  def self.identify(label)
    Zlib.crc32(label.to_s) % MAX_ID
  end

  def self.version
    VERSION
  end

  class << self
    attr_accessor :dbs, :dir, :fixtures
  end

  def self.dbs
    @dbs ||= {}
  end

  def self.dir
    @dir ||= begin
      dir = $LOAD_PATH.detect{|p| Dir.exists?(File.join(p, "fixtures")) }
      if dir
        File.join(dir, "fixtures")
      end
    end
  end

  def self.all_fixtures
    @all_fixtures ||= begin
      unless Dir.exists?(Fixie.dir)
        raise "There is no directory in the $LOAD_PATH with a 'fixtures' directory in it"
      end

      all_fixtures = {}

      now = Time.now.utc

      dbs.each do |db_name, db|
        all_fixtures[db_name] = {}

        # First pass, load all the fixtures
        Dir[File.join(Fixie.dir, "#{db_name}/*.yml")].each do |file|
          table_name = File.basename(file, '.yml')

          fixtures = YAML.load(ERB.new(IO.read(file)).result(binding)).symbolize_keys

          fixtures.each do |name, data|
            data["id"] ||= identify(name)
          end

          all_fixtures[db_name][table_name.to_sym] = fixtures
        end

        # Do a second pass to resolve associations and load data in DB
        all_fixtures[db_name].each do |table_name, fixtures|
          table = db[table_name]
          table_has_created_at = table.columns.include?(:created_at)
          table_has_updated_at = table.columns.include?(:updated_at)

          fixtures.each do |name, data|

            # Change attributes like city: baltimore to city_id: baltimore.id
            data.keys.each do |attr|
              associated_fixtures = all_fixtures[db_name][attr.to_s.pluralize.to_sym]
              if associated_fixtures && table.columns.include?("#{attr}_id".to_sym)
                associated_fixture = associated_fixtures[data[attr].to_sym]
                if associated_fixture
                  data["#{attr}_id"] = associated_fixture['id']
                  data.delete(attr)
                end
              end

              data["created_at"] = now if table_has_created_at && !data.key?("created_at")
              data["updated_at"] = now if table_has_updated_at && !data.key?("updated_at")
            end

            # Set created_at/updated_at if they exist

            # Finally, put the data in the DB
            table.insert(data)
          end
        end
      end

      all_fixtures
    end
  end

  def self.fixture(db_name, table_name, fixture_name)
    db = all_fixtures[db_name]
    if db
      fixtures = db[table_name]
      if fixtures
        fixture = fixtures[fixture_name]
        if fixture
          fixture
        else
          raise "No fixture #{fixture_name.inspect} in #{db_name}.#{table_name}"
        end
      else
        raise "No fixtures for #{table_name.inspect} in #{db_name.inspect}"
      end
    else
      raise "Unknown fixture database #{db_name.inspect}"
    end
  end

  def self.load_fixtures
    Fixie.all_fixtures
  end

  module Model
    # This will return an instance of this class loaded from
    # the fixtures matching the name
    #
    # @param fixture_name [Symbol] The name of the fixture
    # @return [Object] An instance of this class
    def fixture(fixture_name)
      @fixtures ||= {}
      fixture = @fixtures[fixture_name]
      if fixture
        fixture
      else
        @fixtures[fixture_name] = instantiate_from_fixture(Fixie.fixture(fixture_db_name, fixture_table_name, fixture_name))
      end
    end

    # This method is used to get an instance of the model from a fixture hash.
    # The default implementation is to just pass the hash to the model's constructor.
    #
    # @param fixture [Hash<String, Object>] The fixture
    # @return [Object] An instance of this class
    def instantiate_from_fixture(fixture)
      new(fixture)
    end

    # This method determine which database is used to load the fixture.
    # The default implementation is to check the class to see if it has a
    # namespace, like 'Foo::Bar', and if it does, return :foo.
    # If it does not have a namespace, it will return :default.
    #
    # You should override this method if you have multiple databases in your app
    # and you have a different way of determining the DB name based on the class.
    #
    # @return [Symbol] The db name for this class
    def fixture_db_name
      if match_data = name.match(/([^:]+)::/)
        match_data[1].to_sym
      else
        :default
      end
    end

    # This method returns the name of the table that the fixtures for this model
    # should be loaded into/from.  The default is to just underscore and pluralize
    # the table name, e.g. City => cities.
    #
    # @return [Symbol] The table name for this class
    def fixture_table_name
      @fixture_table_name ||= name.demodulize.tableize.to_sym
    end
  end

  extend self
end
