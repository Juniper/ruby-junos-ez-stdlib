# Junos::Ez::Vlans::Provider

Manages Ethernet VLANs.

If you are looking for associating ethernet-ports to VLANs, please refer to the `Junos::Ez::L2ports::Provider` documentation.

# USAGE

The provider *name* selector is the vlan-name, String. 

```ruby
Junos::Ez::Vlans::Provider( ndev, :vlans )

vlan = ndev.vlans["Blue"]

puts "VLAN: #{vlan.name} does not exists!" unless vlan.exists?
```

# PROPERTIES

  - `:vlan_id` - The VLAN tag-id, Fixnum [ 1 .. 4094]
  - `:description` - String description for this VLAN
  - `:no_mac_learning` - [`:enable`, `:disable`].  If `:enable` this VLAN will not learn MAC addresses

# RESOURCE METHODS

## interfaces

This method will return a Hash structure of interfaces bound to this VLAN.
```ruby
ndev.vlans["Green"].interfaces
-> 
{"ge-0/0/22"=>{:mode=>:trunk},
 "ge-0/0/0"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/1"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/2"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/3"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/5"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/6"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/7"=>{:mode=>:trunk, :native=>true},
 "ge-0/0/20"=>{:mode=>:access},
 "ge-0/0/21"=>{:mode=>:access}}
```
