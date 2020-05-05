# -*- encoding: utf-8 -*-
require File.expand_path('../lib/activerecord_bulkoperation/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["OSP"]
  gem.email         = [""]
  gem.summary       = ""
  gem.description   = ""
  gem.homepage      = ""
  gem.license       = "Ruby"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "activerecord_bulkoperation"
  gem.require_paths = ["lib"]
  gem.version       = ActiveRecord::Bulkoperation::VERSION

  gem.required_ruby_version = ">=2.3"

  gem.add_runtime_dependency "activerecord", ">=4.2"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "minitest"
end
