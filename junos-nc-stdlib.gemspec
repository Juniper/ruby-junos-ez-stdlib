$LOAD_PATH.unshift 'lib'
require 'rake'
require 'net/netconf'

Gem::Specification.new do |s|

  s.name = 'junos-nc-stdlib'
  s.version = '0.0.2'
  s.summary = "Junos Standard Libraries for NETCONF"
  s.description = "Junos Standard Libs for application development using NETCONF"
  s.homepage = 'https://github.com/jeremyschulman'
  s.authors = ["Jeremy Schulman"]
  s.email = 'jschulman@juniper.net'

  s.files = FileList[ '*', 'lib/**/*.rb', 'tests/**/*.rb' ]
  s.files.delete 'tests/mylogins.rb'

  s.add_dependency('netconf')
end
