# Junos::Ez::L1ports::Provider

Manages the physical properties of interfaces.

# USAGE

The provider *name* selector is the interface name.

```ruby
Junos::Ez::L1ports::Provider( ndev, :l1_ports )

port = ndev.l1_ports["ge-0/0/12"]

port[:admin] = :down
port.write!
```

# PROPERTIES

  - `:admin` - [:up, :down] - administratively controls the port
  - `:description` - String, description applied at the physical port
  - `:mtu` - Fixnum, MTU value applied at the physical port
  - `:speed` - Link Speed, [:auto, '10m', '100m', '1g', 10g']
  - `:duplex` - Link Duplex, [:auto, :half, :full]
  - `:unit_count` - **READ-ONLY** indicates the number of logical ports (units) configured

# METHODS

No additional methods at this time ...
