# Junos::Ez::LAGports::Provider

Manages Link Aggregation Group (LAG) port properties

# USAGE

The provider *name* selector is the interface name, e.g. "ae0".

```ruby
Junos::Ez::LAGports::Provider( ndev, :lags )

port = ndev.lags["ae0"]

port[:links] = ["ge-0/0/0", "ge-0/0/1", "ge-0/0/2", "ge-0/0/3"]
port[:lacp] = :active
port[:minimum_links] = 2

port.write!
```

# PROPERTIES

  - `:links` - Set of interface names
  - `:lacp` - [:active, :passive, :disabled], :disabled is default
  - `:minimum_links` - number of interfaces that must be active for LAG to be declared 'up'

# METHODS

No additional methods at this time ...
