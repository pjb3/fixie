require 'fixie/version'
require 'active_support/core_ext'
require 'erb'
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
    attr_accessor :db, :dir, :fixtures
  end

  def self.dir
    @dir ||= begin
      dir = $LOAD_PATH.detect{|p| Dir.exists?(File.join(p, "fixtures")) }
      if dir
        File.join(dir, "fixtures")
      end
    end
  end

  def self.included(cls)
    fixtures # load the fixtures
  end

  def self.fixtures
    @fixtures ||= begin
      all_fixtures = {}

      unless Dir.exists?(Fixie.dir)
        raise "There is no directory in the $LOAD_PATH with a 'fixtures' directory in it"
      end

      # First pass, load all the fixtures
      Dir[File.join(Fixie.dir, "**/*.yml")].each do |file|
        fixture_name = File.basename(file, '.yml')
        fixture_class = fixture_name.singularize.classify.constantize

        fixtures = YAML.load(ERB.new(IO.read(file)).result(binding)).symbolize_keys

        fixtures.each do |name, data|
          data["id"] ||= identify(name)
        end

        unless respond_to?(fixture_name)
          define_method(fixture_name) do |fixture|
            fixture_class.new(fixtures[fixture])
          end
        end

        all_fixtures[fixture_name.to_sym] = fixtures
      end

      # Do a second pass to resolve associations
      all_fixtures.each do |fixture_name, fixtures|
        fixture_class = fixture_name.to_s.singularize.classify.constantize
        fixtures.each do |name, data|
          data.keys.each do |attr|
            associated_fixtures = all_fixtures[attr.to_s.pluralize.to_sym]
            if associated_fixtures && fixture_class.method_defined?("#{attr}_id=")
              associated_fixture = associated_fixtures[data[attr].to_sym]
              if associated_fixture
                data["#{attr}_id"] = associated_fixture['id']
                data.delete(attr)
              end
            end
          end
          db[fixture_name].insert(data)
        end

      end

      all_fixtures
    end
  end

  extend self
end
