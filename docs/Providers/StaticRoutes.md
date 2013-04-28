# Junos::Ez::StaticRoutes::Provider

Manages static route entries.

_NOTE: for now, routing-instances are not supported, but under review for upcoming release..._

# USAGE

The provider *name* is the target-route.  If you want to specify the default-route, you can either use "0.0.0.0/0" or the special name `:default`.

```ruby
Junos::Ez::StaticRoutes::Provider( ndev, :route )

default = ndev.route[:default]

unless default.exists?
  default[:gateway] = "192.168.1.1"
  default.write!
end
```

# PROPERTIES

  - `:gateway` - The next-hop gateway.  Could be single String or Array-of-Strings
  - `:metic` - The metric assigned to this route, Fixnum
  - `:action` - Configures the route action, [:reject, :discard, :receive]
  - `:active` - Configures the route active, [true, false, nil]
  - `:retain` - Configures the ratain/no-retain flag, [ nil, true, false ]
  - `:install` - Configures the install/no-install flag, [nil, true, false ]
  - `:readvertise` - Configures the readvertise/no-readvertise flag, [nil, true, false]
  - `:resovlve` - Configures the resolve/no-resolve falg, [nil, true, false]

In the above "flag controls", assigning the values [true | false] configures if the flat is set or "no-" set respectively.  To delete the flag from the configuration, set the property to `nil`.

# METHODS

No additional methods at this time ...
