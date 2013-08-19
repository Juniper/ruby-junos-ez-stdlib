# Junos::Ez::LAGports::Provider

Manages Link Aggregation Group (LAG) port properties

# EXAMPLE

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

# USAGE NOTES

### Allocating Aggregated Ethernet (AE) Ports in Junos

Before using LAG ports, you must first configured the "aggregated ethernet ports" device count in Junos.  This is done under the `[edit chassis]` stanza as shown:

````
{master:0}[edit chassis]
jeremy@switch# show
aggregated-devices {
    ethernet {
        device-count 10;
    }
}
````

### Changing the Links Property

The `:links` property is internally managed as a Ruby Set.  When modifing the `:links` property you must use an Array notation, even if you are simply adding or removing one link. For example:

````ruby
port = ndev.lags["ae0"]

port[:links] += ["ge-0/0/15"]
port.write!
````

