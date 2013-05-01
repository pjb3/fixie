require 'test/unit'
require 'logger'
require 'sequel'
require 'sqlite3'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'fixie'

class Model
  attr_accessor :id

  def initialize(attrs={})
    attrs.each do |attr, value|
      send("#{attr}=", value)
    end
  end
end

class Country < Model
  attr_accessor :name, :code
end

class City < Model
  attr_accessor :name, :country, :country_id, :created_at
end

db = Sequel.sqlite(logger: Logger.new("log/test.log"))

db.create_table :countries do
  primary_key :id
  String :name
  String :code
end

db.create_table :cities do
  primary_key :id
  Integer :country_id
  String :name
  String :nick_name
  Time :created_at
end

Fixie.dbs[:default] = db

module FakeGetText
  def _(key)
    key.to_s.titleize
  end
end

Fixie.extend FakeGetText
Fixie.load_fixtures
Model.extend Fixie::Model

class FixieTest < MiniTest::Unit::TestCase

  def test_explicit_id
    assert_equal "United States", Country.fixture(:us).name
    assert_equal 1, Country.fixture(:us).id
  end

  def test_implicity_id
    assert_equal "Canada", Country.fixture(:canada).name
    assert_equal 842554592, Country.fixture(:canada).id
  end

  def test_association
    assert_equal Country.fixture(:us).id, City.fixture(:baltimore).country_id
    # TODO: make this work
    # assert_equal countries(:us), City.fixture(:baltimore).country
  end

  def test_get
    assert_equal "US", Fixie.fixture(:default, :countries, :us)["code"]
  end

  def test_loaded_in_db
    assert_equal ["CA","US"], Fixie.dbs[:default][:countries].all.map{|c| c[:code] }.sort
  end

  def test_erb
    assert_equal Time, City.fixture(:baltimore).created_at.class
  end

  def test_erb_is_evaled_in_context_of_fixie
    assert_equal "Baltimore", City.fixture(:baltimore).name
  end
end
