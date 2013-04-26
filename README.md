# OVERVIEW

Ruby framework to support Junos OS based device management automation.  This is the "standard library" or "core" 
set of functionality that should work on most/all Junos OS based devices.  The purpose of this framework is
to enable automation development without requiring specific Junos XML knowledge or domain experties.

Further documentation can be found in the *docs* subdirectory.

# FEATURES

The framework is comprised of three basic eloements:

  - Facts: A Hash of name/value pairs of information auto-collected.  Fact values can be Hash structures as well
    so you can have deeply nested fact data.  You can also define your own facts in addition to the "stdlib" facts.
    
  - Proviers/Resources: 
  
  - Utilities:
  
# UTILITIES

# PROVIDERS
  
# EXAMPLE USAGE
  
````ruby
require 'pp'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'

unless ARGV[0]
   puts "You must specify a target"
   exit 1
end

# login information for NETCONF session 
login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
print "Connecting to device #{login[:target]} ... "
ndev.open
puts "OK!"

## Now bind providers to the device object.
## the 'Junos::Ez::Provider' must be first before all others
## this provider will setup the device 'facts'.  The other providers
## allow you to define the instance variables; so this example
## is using 'l1_ports' and 'ip_ports', but you could name them
## what you like, yo!

Junos::Ez::Provider( ndev )
Junos::Ez::L1ports::Provider( ndev, :l1_ports )
Junos::Ez::IPports::Provider( ndev, :ip_ports )

## drop into interactive mode to play around ... let's look
## at what the device has for facts ...

pp ndev.facts.list
pp ndev.facts.catalog
pp ndev.fact :version

## now look at specific providers like the physical (l1) ports ...

pp ndev.l1_ports.list
pp ndev.l1_ports.catalog

ndev.close
````
  
# DEPENDENCIES

  * gem netconf
  * Junos OS based products, see TESTED-DEVICES.md
  
# INSTALLATION 

  * gem install junos-ez-stdlib

# CONTRIBUTORS

  * Jeremy Schulman, @nwkautomaniac

# LICENSES

   BSD-2, See LICENSE file
