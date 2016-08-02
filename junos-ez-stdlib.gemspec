# frozen_string_literal: true
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'junos-ez/version'

Gem::Specification.new do |spec|
  spec.name = 'junos-ez-stdlib'
  spec.version = Junos::Ez::VERSION
  spec.authors = ['Jeremy Schulman', 'John Deatherage', 'Nitin Kumar', 'Priyal Jain', 'Ganesh Nalawade']
  spec.email = 'jnpr-community-netdev@juniper.net'

  spec.summary = 'Junos EZ Framework - Standard Libraries'
  spec.description = 'Automation Framework for Junos/NETCONF:  Facts, Providers, and Utils'
  spec.homepage = 'https://github.com/Juniper/ruby-junos-ez-stdlib'
  spec.license = 'BSD-2-Clause'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.add_dependency('netconf', '~> 0.2.5')

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.42.0'
end
