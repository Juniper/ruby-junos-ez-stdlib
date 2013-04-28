# Junos::Ez::StaticHosts::Provider

Manages locally configured host-name to IPv4 & IPv6 address mapping

# USAGE

The provider *name* is the host-name as it would have been configured under `[edit system static-host-mapping]`

```ruby
Junos::Ez::StaticHosts::Provider( ndev, :etc_hosts )

host = ndev.etc_hosts["ex4.jeremylab.net"]
host[:ip] = "192.168.10.24"
host.write!
```

# PROPERITES

  - `:ip` - The IPv4 address
  - `:ip6` - The IPv6 address

_NOTE: A host entry **can** have both IPv4 and IPv6 addresses assigned at the same time_

# METHODS

No additional methods at this time ...
