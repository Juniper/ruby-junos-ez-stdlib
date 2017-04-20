[![Gem Version](https://badge.fury.io/rb/junos-ez-stdlib.svg)](https://badge.fury.io/rb/junos-ez-stdlib)[![Dependency Status](https://gemnasium.com/badges/github.com/Juniper/ruby-junos-ez-stdlib.svg)](https://gemnasium.com/github.com/Juniper/ruby-junos-ez-stdlib)
[![Build Status](https://travis-ci.org/Juniper/ruby-junos-ez-stdlib.svg?branch=master)](https://travis-ci.org/Juniper/ruby-junos-ez-stdlib)

# OVERVIEW

Ruby framework to support Junos OS based device management automation.  

This is the "standard library" or "core" set of functionality that should work on most/all Junos OS based devices.  

This framework is build on top of the NETCONF gem which uses XML as the fundamental data-exchange.  So no
"automating the CLI" or using SNMP.  The purpose of this framework is to **enable automation development
without requiring specific Junos XML knowledge**.

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
    The purpose of a provider/resource is to automate the life-cycle of common changes, like adding
    VLANs, or ports to a VLAN.  A provider also allows you to obtain a `list` of resources
    (Array of *names*) or a `catalog` (Hash of resource properties).  Providers may include resource
    specific functionality, like using complex YAML/Hash data for easy import/export and provisioning
    with Junos.  If you need the ability to simply apply config-snippets that you do not need to model
    as resources (as you might for initial device commissioning), the Utilities library is where you
    want to start.

  - Utilities:

    Utilities are simply collections of functions.  The **configuration** utilities, for example, will
    allow you to easily push config snippets in "curly-brace", "set", or XML formats.  Very useful
    for unmanaged provider/resources (like initial configuration of the device).  The
    **routing-engine** utilities, for example, will allow you to easily upgrade software, check
    memory usage, and do `ping` operations.

# EXAMPLE USAGE

```ruby
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

## Now bind providers to the device object. The 'Junos::Ez::Provider' must be first.
## This will retrieve the device 'facts'.  The other providers allow you to define the
## provider variables; so this example is using 'l1_ports' and 'ip_ports', but you could name
## them what you like, yo!

Junos::Ez::Provider( ndev )
Junos::Ez::L1ports::Provider( ndev, :l1_ports )
Junos::Ez::IPports::Provider( ndev, :ip_ports )
Junos::Ez::Config::Utils( ndev, :cu )

# -----------------------------------------------------------
# Facts ...
# -----------------------------------------------------------

# show the device softare version fact
pp ndev.fact :version

# show the device serial-number face
pp ndev.fact :serialnumber

# get a list of all available facts (Array)
pp ndev.facts.list

# get a hash of all facts and their associated values
pp ndev.facts.catalog

# -----------------------------------------------------------
# Layer 1 (physical ports) Resources ...
# -----------------------------------------------------------

pp ndev.l1_ports.list
pp ndev.l1_ports.catalog

# select port 'ge-0/0/0' and display the contents
# of the properties (like port, speed, description)

ge_0 = ndev.l1_ports['ge-0/0/0']
pp ge_0.to_h

# change port to disable, this will write the change
# but not commit it.

ge_0[:admin] = :down
ge_0.write!

# show the diff of the change to the screen

puts ndev.cu.diff?

# now rollback the change, since we don't want to save it.

ndev.cu.rollback!

ndev.close
```

# PROVIDERS

Providers manage access to individual resources and their associated properties.  Providers/resources exists
for managing life-cycle common changes that you generally need as part of a larger workflow process.  For more
documentation on Providers/Resources, see the *docs* directory.

  - L1ports: Physical port management
  - L2ports: Ethernet port (VLAN) management
  - Vlans: VLAN resource management
  - IPports: IP v4 port management
  - StaticHosts: Static Hosts [system static-host-mapping ...]  
  - StaticRoutes: Static Routes [routing-options static ...]
  - Group: JUNOS groups management

# UTILITIES

  - Config:

    These functions allow you to load config snippets, do commit checks, look at config diffs, etc.
    Generally speaking, you would want to use the Providers/Resources framework to manage specific
    items in the config.  This utility library is very useful when doing the initial commissioning
    process, where you do not (cannot) model every aspect of Junos.  These utilities can also be
    used in conjunction with Providers/Resources, specifically around locking/unlocking and committing
    the configuration.

  - Filesystem:

    These functions provide you "unix-like" commands that return data in Hash forms rather than
    as string output you'd normally have to screen-scraps.  These methods include `ls`, `df`, `pwd`,
    `cwd`, `cleanup`, and `cleanup!`

  - Routing-Engine:

    These functions provide a general collection to information and functioanlity for handling
    routing-engine (RE) processes.  These functions `reboot!`, `shutdown!`, `install_software!`,
    `ping`.  Information gathering such as memory-usage, current users, and RE status information
    is also made available through this collection.

# DEPENDENCIES

  * gem netconf
  * Junos OS based products

# INSTALLATION

  * gem install junos-ez-stdlib

# CONTRIBUTORS
  Juniper Networks is actively contributing to and maintaining this repo. Please contact jnpr-community-netdev@juniper.net
  for any queries.

  Contributors:
  [John Deatherage](https://github.com/routelastresort), [Nitin Kumar](https://github.com/vnitinv),
  [Priyal Jain](https://github.com/jainpriyal), [Ganesh Nalawade](https://github.com/ganeshrn)

  Former Contributors:  
  [Jeremy Schulman](https://github.com/jeremyschulman)

# LICENSES

   BSD-2, See LICENSE file

# SUPPORT

Support for this software is made available exclusively through Github repo issue tracking.  You are also welcome to contact the CONTRIBUTORS directly via their provided contact information.  

If you find a bug, please open an issue against this repo.

If you have suggestions or ideas, please write them up and add them to the "SUGGESTION-BOX" folder of this repo (via pull request).  This way we can share the ideas with the community and crowdsource for feature delivery.

Thank you!
