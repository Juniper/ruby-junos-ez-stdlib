# OVERVIEW

Ruby framework to support Junos OS based device management automation.  

This is the "standard library" or "core" set of functionality that should work on most/all Junos OS based devices.  

This framework is build on top of the NETCONF gem which uses XML as the fundamental data-exchange.  So no 
"automating the CLI" or using SNMP.  The purpose of this framework is to **enable automation development 
without requiring specific Junos XML knowledge or domain expertise**.

Further documentation can be found in the *docs* subdirectory.

# FRAMEWORK

The framework is comprised of these basic eloements:

  - Facts: 

    A Hash of name/value pairs of information auto-collected.  Fact values can be Hash structures as well
    so you can have deeply nested fact data.  You can also define your own facts in addition to the "stdlib" facts.
    The facts are used by the framework to create a platform indepent layer of abstraction.  This means
    that managing a VLAN, for example, is the same regardless of the underlying hardware platofrm (EX, QFX,
    MX, SRX, ...)
    
  - Resources: 

    Resources allow you to easily configure and perform operational functions on specific items within Junos, 
    for example VLANs, or switch ports.  A resource has *properties* that you manipuate as Hash.  You can
    interact with Junos using resource methods like `read!`, `write!`, `delete!`, `activate!`, `deactivate!`, etc. 
    For a complete listing of resource methods, refer to the *docs* directory
    
  - Providers:

    Providers allow you to manage a collection of resource, and most commonly, select a resource.  
    A provider also allows you to obtain a list of resources (Array of *names*) or a catalog 
    (Hash of resource properties).  Providers may include resource specific functionality, like using 
    complex YAML/Hash data for easy import/export and provisioning with Junos
  
  - Utilities:

    Utilities are simply collections of functions.  The **configuration** utilities, for example, will
    allow you to easily push config snippets in "curly-brace", "set", or XML formats.  The
    **routing-engine** utilities, for example, will allow you to easily upgrade software, check
    memory usage, and do `ping` operations.
  
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
  
# PROVIDERS


# UTILITIES

  - Config:
    
    These functions allow you to load config snippets, do commit checks, look at config diffs, etc.
    Generally speaking, you would want to use the Providers/Resources framework to manage specific 
    items in the config.  This utility library is very useful when doing the initial commissioning
    process, where you do not (cannot) model every aspect of Junos.  These utilities can also be
    used in conjunction with Providers/Resources, specifically around locking/unlocking and committing
    the configuration.
  
  - Filesystem:
  - Routing-Engine:

# DEPENDENCIES

  * gem netconf
  * Junos OS based products, see TESTED-DEVICES.md
  
# INSTALLATION 

  * gem install junos-ez-stdlib

# CONTRIBUTORS

  * Jeremy Schulman, @nwkautomaniac

# LICENSES

   BSD-2, See LICENSE file
