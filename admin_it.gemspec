lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'admin_it/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.0.0'

  spec.name          = 'admin_it'
  spec.version       = AdminIt::VERSION
  spec.authors       = ['Alexey Ovchinnikov']
  spec.email         = ['alexiss@cybernetlab.ru']
  spec.description   = %q(Admin interface)
  spec.summary       = %q(Admin interface)
  spec.homepage      = 'https://github.com/cybernetlab/admin_it'
  spec.license       = 'MIT'
  spec.metadata      = {
    'issue_tracker' => 'https://github.com/cybernetlab/admin_it/issues'
  }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '~> 4.0'
  spec.add_dependency 'devise'
  spec.add_dependency 'wrap_it'
  spec.add_dependency 'ensure_it'
  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'select2-rails'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'redcarpet', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'combustion'
end
