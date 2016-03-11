$LOAD_PATH.unshift 'lib'
require 'rake'
require 'junos-ez/version'

Gem::Specification.new do |s|
  s.name = 'junos-ez-stdlib'
  s.version = Junos::Ez::VERSION
  s.summary = "Junos EZ Framework - Standard Libraries"
  s.description = "Automation Framework for Junos/NETCONF:  Facts, Providers, and Utils"
  s.homepage = 'https://github.com/Juniper/ruby-junos-ez-stdlib'
  s.authors = ["Jeremy Schulman", "John Deatherage", "Nitin Kumar, "Priyal Jain", "Ganesh Nalawade"]
  s.email = 'jnpr-community-netdev@juniper.net'
  s.files = FileList[ '*', 'lib/**/*.rb', 'examples/**/*.rb', 'docs/**/*.md' ]
  s.add_dependency('netconf', ">= 0.2.5")
end
