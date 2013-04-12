# Fixie

A standalone library for managing test fixture data

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
        ├── cities.yml
        └── countries.yml

Fixie use Sequel to load the data into the database.  Fixie will work even if you aren't using Sequel in your application.  You must configure the Fixie database and then include the Fixie module in your test class to use it.  Your test helper might look like this:

``` ruby
Fixie.db = Sequel.sqlite

class Test::Unit::TestCase
  include Fixie
end
```

Now all the fixtures will be loaded into the test database, and you can access them from within a test like this:

``` ruby
def test_something
  assert_equal "US", countries(:us)
end
```

You can also access the fixtures in any context once they have been loaded like this:

``` ruby
Fixie.countries(:us)
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
Fixie.extend(FastGettext::Translation)
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
