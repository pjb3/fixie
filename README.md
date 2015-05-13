# Fixie

A standalone library for managing test fixture data with good support for multiple databases.

## Installation

Add this line to your application's Gemfile:

    gem 'fixie'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fixie

## Usage

To use Fixie, you first create some fixture files in a directory called `fixtures` somewhere in your load path, typically in the `test` directory:

    test/
    └── fixtures
        └── default
            ├── cities.yml
            └── countries.yml

You must put all your fixtures into a subdirectory of the `fixtures` directory.  The name of the directory should be a good logical name for the database that the fixtures.  If you have only one database, you should use `default` as the name, but if you have an app with customers in one database and orders in another, you would name them `customers` and `orders`.

Fixie uses Sequel to load the data into the database.  Fixie will work even if you aren't using Sequel in your application.  You must configure the Fixie databases and then call `load_fixtures` to get the fixtures to actually be loaded.  Your test helper might look like this:

``` ruby
Fixie.dbs[:default] = Sequel.sqlite

Fixie.load_fixtures
```

Now all the fixtures will be loaded into the default database.  In order to access them from a test, you can the fixture as a Hash like this:

``` ruby
Fixie::Fixtures.countries(:us)
```

You can also include the `Fixie::Fixtures` model in your tests and then just call the method directly:

``` ruby
include Fixie::Fixtures

def test_something
  assert_equal "US", countries(:us)
end
```

If you have models in your application and you want to get instances of the model back instead of Hashes, you need to mix the `Fixie::Model` module into the base class of your models.  For example, say you have models defined like this:

``` ruby
class Model
end

class Country < Model
end

class City < Model
end
```

In your test helper, you mix in `Fixie::Model` like this:

``` ruby
Model.extend Fixie::Model
```

Now in your tests, you can refer to fixtures like this:

``` ruby
def test_something
  assert_equal "US", Country.fixture(:us)
end
```

Fixtures are defined in YAML files like this:

``` yaml
us:
  id: 1
  name: United States
```

If left out, the value for the `id` attribute will be automatically generated based on the name of the fixture:

``` yaml
us:
  name: United States
```

You can then use it in other fixtures to reference the other record by name instead of id:

``` yaml
baltimore:
  name: Baltimore
  country: us
```

You can also use ERB in the YAML files:

``` yaml
baltimore:
  name: Baltimore
  country: us
  created_at: <%= Time.now %>
```

The ERB is evaluated in the context of the Fixie module, so if there is anything else you want to make available in that context, just mix the module into Fixie:

``` ruby
Fixie.extend FastGettext::Translation
```

``` yaml
baltimore:
  name: <%=_ "Baltimore" %>
  country: us
  created_at: <%= Time.now %>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
