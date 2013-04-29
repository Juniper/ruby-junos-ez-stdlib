# Junos::Ez::L2ports::Provider

Manages the ethernet switch ports.  The primary function is to associate switching ports to VLANs.

Currently the association of VLANS to ports is read/write under the interfaces stanza.  Junos OS also supports
the association under the VLAN resource stanza (vlans/bridge-domains).  

_NOTE: this provider does not use the VLAN resource stanza at this time.  Under review now.  If you have an opionin on this, please let us know, thank you!_ 

# USAGE

The provider *name* is the interface.  The framework will assume unit 0 if the name does not indicate one.

```ruby
Junos::Ez::L2ports::Provider( ndev, l2_ports )

port = ndev.l2_ports["ge-0/0/12"]

puts "port #{port.name} is not a switch-port!" unless port.exists?
```

# PROPERTIES

  - `:description` - String description at the logical interface level
  - `:untagged_vlan` - String, VLAN-name for packets without VLAN tags
  - `:tagged_vlans` - Array of VLAN-names for packets with VLAN tags
  - `:vlan_tagging` - [true | false] - indicates if this port accepts packets with VLAN tags

# METHODS

No additional methods at this time ...

# SUPPORTED PLATFORMS

  - EX2200, EX3200, EX3300, EX4200, EX4500, EX4550, EX6100, EX8200
  - SRX branch: **entire product line, but not vSRX**
  - QFX3500, QFX3600
  
Comming soon:

  - EX platforms released in 2013
  - MX5, MX10, MX40, MX80, MX240, MX480, MX960

