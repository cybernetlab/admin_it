source 'https://rubygems.org'

gemspec

# integration includes
gem 'activerecord' if ENV['USE_ACTIVERECORD']
if ENV['USE_MONGOID']
  gem 'mongoid', github: 'mongoid/mongoid'
  gem 'bson_ext'
  gem 'bson'
  gem 'moped', github: 'mongoid/moped'
end
