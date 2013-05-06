# FACT KEEPING

This framework is *fact based*, meaning that the provider libraries will have access to information about each
target.  Facts enable the framework to abstract the physical differences of the underlying hardware.  

For example,the `Junos::Ez::Vlans::Provider` allows you to manage vlans without having to worry about the differences between the EX product family and the MX product family.  To you, the programmer, you simply obtain a resource and manage the associated properties.

There are collection of standard facts that are always read by the framework.  You can find a list of these and the assocaited code in the *libs/../facts* subdirectory.  These facts are also avaialble to your program as well.  So you can make programmatic decisions based on the facts of the device.

You can also define your own facts, and then go on to building your own provider libraries (but we're getting ahead of ourselfs here ...)

# USAGE

Usage rule: you **MUST** call `Junos::Ez::Provider` on your netconf object:

  - **AFTER** the object has connected to the target, since it will read facts
  - **BEFORE** you add any other providers, since these may use the facts
  
Here is a basic example:

```ruby
require 'pp'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'

login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }

# create a NETCONF object to manage the device

ndev = Netconf::SSH.new( login )

# open the NETCONF connetion, if this fails, the object will throw an exception
ndev.open

# now that the netconf session has been established, initialize the object for the
# Junos::Ez framework.  This will add an instance variable called `@facts` and
# retrieve all known facts from the target

Junos::Ez::Provider( ndev )

# do a quick dump of all facts

pp ndev.facts.catalog
-> 
{:hardwaremodel=>"SRX210H",
 :serialnumber=>"AD2909AA0096",
 :hostname=>"srx210",
 :domain=>"workflowsherpas.com",
 :fqdn=>"srx210.workflowsherpas.com",
 :RE=>
  {:status=>"OK",
   :model=>"RE-SRX210H",
   :up_time=>"26 days, 15 hours, 46 minutes, 4 seconds",
   :last_reboot_reason=>"0x200:normal shutdown"},
 :personality=>:SRX_BRANCH,
 :ifd_style=>:CLASSIC,
 :switch_style=>:VLAN,
 :version=>"12.1X44-D10.4"}
```

# STANDARD FACTS

The following facts are provided by the `Junos::Ez::Provider` framework:
```
:hardwaremodel => String
```
Identifies the target hardware model as obtained from the chassis inventory information
```
:serialnumber => String
```
Identifies the target chassis serial-number as obtained from the chassis inventory information
```
:hostname => String
```
Identifies the target host-name as obtained from the system configuration
```
:domain => String
```
Identifies the target domain-name as obtained from the system configuration
```
:fqdn => String
```
Identifies the target Fully-Qualified-Domain-Name (FQDN), which is the composite of the `:hostname` and `:domain` facts.
```
:version => String
```
Identifies the Junos version string, e.g. "12.3R2.5" running on the master routing-engine.
```
:version_<RE | FPC + ID> => String
```
When the target is a multi-routing-engine or virtual-chassis system, the version loaded on each control processor is provided as a separate version fact.  All version facts begin with `version_`.  So and MX router with two routing-engines would have `:version_RE0` and `:version_RE1` in additon to the `:version` fact.  An EX vritual chassis with two members would have `:version_FPC0` and `:version_FPC1` facts in additon to the `:version` fact.
```
:master => Fixnum
```
If the target is a multi-routing-engine capabile, this fact will identify the master RE


```
:switch_style => [:VLAN, :BRIDGE_DOMAIN, :VLAN_ELS, :NONE]
```
Identifies the target style for handing vlan configurations.  If the target does not support vlan briding (for example the vSRX), then the style will be set to `:NONE`.  
```
:personality => [:SWITCH, :MX, :SRX_BRANCH, :SRX_HIGHEND]
```
Identifies the personality of the target.
```
:ifd_style => [:CLASSIC, :SWITCH]
```
Identifies the target style for handling interface configuration differences.

# METHODS
  
  - `read!` - reloads the facts from the target
  - `facts[]` - retrieve a specific fact from the keeper
  - `fact` - alternative method to retrieve a specific fact from the keeper
  - `list`, `list!` - returns an Array of fact names (symbols)
  - `catalog`, `catalog!` - returns a Hash of fact names and values
  
The bang (!) indicates that the method will re-read the value from the target, which the non-bang method uses the values cached in memory.  If the cache does not exist, the framework will read the values. The use of the bang-methods are handy if/when you have facts whose values change at runtime, like the `ndev.fact(:RE)[:up_time]`

# CREATING CUSTOM FACTS

You can define your own facts using `Junos::Ez::Facts::Keeper.define`.  You can review the stdlib facts by looking the *libs/../facts* subdirectory of this repo.  Here is the code for the `:chassis` fact.  What is interesting about this example, is this code will actually create multiple facts about the chassis.  So there is not a required one-to-one relationship between createing a custom fact and the actual number of facts it creates, yo!

When you define your fact, you must give it a unique "fact name*, and a block.  The block takee two arguments: the first is the netconf object, which will provide you access to the underlying Junos XML netconf, an a Hash that allows you to write your facts into the Keeper:

```ruby
Junos::Ez::Facts::Keeper.define( :chassis ) do |ndev, facts|
  
  inv_info = ndev.rpc.get_chassis_inventory
  chassis = inv_info.xpath('chassis')
  
  facts[:hardwaremodel] = chassis.xpath('description').text
  facts[:serialnumber] = chassis.xpath('serial-number').text           
  
  cfg = ndev.rpc.get_configuration{|xml|
    xml.system {
      xml.send(:'host-name')
      xml.send(:'domain-name')
    }
  }
  
  facts[:hostname] = cfg.xpath('//host-name').text
  facts[:domain] = cfg.xpath('//domain-name').text
  facts[:fqdn] = facts[:hostname]
  facts[:fqdn] += ".#{facts[:domain]}" unless facts[:domain].empty?
  
end
```






