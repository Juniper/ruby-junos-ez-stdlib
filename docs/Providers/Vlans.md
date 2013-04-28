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
  - `:no_mac_learning` - If `true` this VLAN will not learn MAC addresses

# RESOURCE METHODS

## interfaces

This method will return a Hash structure of interfaces bound to this VLAN.
