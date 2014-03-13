module ExtendIt
  module Refines; end
end

glob = File.extend_path(File.join(%w(.. refines ** *.rb)), __FILE__)
Dir[glob].each { |file| require(file) }
