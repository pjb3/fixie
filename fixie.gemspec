# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fixie"
  gem.version       = "0.5.0"
  gem.authors       = ["Paul Barry"]
  gem.email         = ["mail@paulbarry.com"]
  gem.description   = %q{A standalone library for managing test fixture data}
  gem.summary       = %q{A standalone library for managing test fixture data}
  gem.homepage      = "http://github.com/pjb3/fixie"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "activesupport"
  gem.add_runtime_dependency "sequel"
  gem.add_development_dependency "sqlite3"
end
