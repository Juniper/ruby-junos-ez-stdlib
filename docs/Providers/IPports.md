# Junos::Ez::IPports::Provider

Manages IPv4 ports.  For now, ports recognized are:

  - Fast Ethernet: `fe-*`
  - Gigabit Ethernet: `ge-*`
  - 10 Gigabit Ethernet: `xe-*`

IPv6 ports are a different provider (comming soon...)

# USAGE

The provider *name* selector is the interface.  If the *name* does not include the ".0" unit, the framework will default to this.

```ruby
Junos::Ez::IPports::Provider( ndev, :ip_ports )

port = ndev.ip_ports["ge-0/0/8"]

puts "IPv4 port #{port.name} does not exist!" unless port.exists?
```

# PROPERTIES

  - `:admin` - [:up, :down] - administrative control of the port
  - `:description` - String, description assigned at the interface unit level
  - `:tag_id` - Fixnum, used if the phyiscal port is vlan-tagging (but not L2port)
  - `:mtu` - Fixnum, MTU value assigned for IP packets (but not L1port MTU)
  - `:address` - String in "ip/prefix" format.  For example "192.168.10.12/24"
  - `:acl_in` - Name of input ACL (firewall-filter)
  - `:acl_out` - Name of output ACL

# METHODS

No additional methods are available at this time ....
