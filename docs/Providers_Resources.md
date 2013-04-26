# RESOURCES

Let's start with Resources before we get to Providers.  Resources are generally where all "the action" happens. 
The primary purpose of a resource is to allow you to make configuration changes without having to know
the underlying Junos XML configuration.  When you have a resource, you can always get a list of the properties 
available to you.  Here's an example of looking at a an ethernet switching port using the L2ports provider.
This is just a snippet of code, so for now, know that `l2_ports` is the provider assigned to the `ndev` object.

```ruby

# select a port by name from the provider

port = ndev.l2_ports['ge-0/0/0']

# check to see if this actually exists in the config

unless port.exists?
  puts "This port #{port.name} does not exist!"
  exit 1
end

# now pretty-print the properties associated with this resource (which would be the same list for
# any L2port resource

pp port.properties

## [:_exist, :_active, :description, :untagged_vlan, :tagged_vlans, :vlan_tagging]

# now look at the specific values for this resource by pp the assocaite hash

pp port.to_h

# {"ge-0/0/0"=>
#   {:_active=>true,
#    :_exist=>true,
#    :vlan_tagging=>true,
#    :tagged_vlans=>["Red", "Green", "Blue"],
#    :untagged_vlan=>nil}}
```

## Resource Methods

  - `read!` - reads the contents into the resource read-hash (@has)
  - `write!` - writes the contents from the resource write-hash (@should) to the device
  - `delete!` - delete the resource from the configuration
  - `activate!` - activates the configuration for this resource
  - `deactivate!` - deactivates the configuration for this resource
  - `rename!` - renames the resource in the configuration
  - `reorder!` - reorders (Junos `insert`) the resource in the configuration
  - `exists?` - indicates if this resource exists in the configuration
  - `active?` - indicates if this resource is active in the configuration
  - `to_h` - return the read-from and write-to hash values

## Instance Variables

Each resource include a hash structure containing the values read-from the device.  This is
the `@has` variable.  When modifying properties, the changed values are stored in the
write-to hash `@should` variable.  These instance variable are made accessible, but you
should not access them directly.  See next section for changing the property values.

## Modifying Properties

Modifying the resource property is simply making use of the []= operator.  For example,
setting the `:untagged_vlan` to "Black" and writing that back to the device would
look something like this:

```ruby
port[:untagged_vlan] = "Black"
port.write!
```

When you execute the `write!` method, the framework will examine the contents of
the `@should` hash to determine what changes need to be made.  On success the
values are then transfered into the `@has` hash.

If you're going to make changes to an array property, you would need to do something like this:

```ruby
port[:tagged_vlans] += ["Purple"]
port[:tagged_vlans] -= ["Red", "Green"]
port.write!
```

_NOTE: for Array values, do not use array methods like `delete` as they will operate
on the `@has` hash._

## Special Properties

All resources include two special properties `_exist` and `_active`.  These control whether or
not a resource exists (or should) and whether or not the resource is active (or deactive).  
Generally speaking you should not modify these properties directly.  Rather you should use the
`delete!` method to remove the resource and the `activate!` and `deactivate!` methods respectively.
That being said, if you have a Hash/YAML dataset that explicity has `:_exist => false` when that
resource is applied to the device, the resource is deleted.  This is handy to ensure a specific
resource does not exist, for example.

# PROVIDERS

Providers enable access to resources.  So how to you bind a provider to a Netconf::SSH (netconf) object?
This is done by the provider's `Provider` method.  For example, if you want to use the
L2port provider, you bind it to the netconf object like so:

```ruby

# creating a netconf object, here login is a hash defining login info

ndev = Netconf::SSH.new( login )

# connect to the target

ndev.open

# bind providers to this object

Junos::Ez::Provider( ndev )
Junos::Ez::L2ports::Provider( ndev, :l2_ports )
```

There are a few things to note on this example:

  1.  This framework is built around the NETCONF gem as all of the underlying code access the Junos XML
      API via the NETCONF protocol

  2.  You **MUST** use the `Junos::Ez::Provider` before any other providers as this sets up the `Netconf::SSH`
      object for future bindings.

  3.  **You** get to chose the provider instance variable name (in this case `l2_ports`, there are is no 
      hard-coding going on in this framework, yo! (except for the `facts` variable)

## Listing Providers on a Netconf::SSH Object

When you bind providers to a `Netconf::SSH` object, you can always get a list of what exists:

```ruby
pp ndev.providers

# [:l1_ports, :ip_ports, :l2_ports]
```

In a future rev of this framework, this may include not only the instance variable, but also the
provider's Class. But you can always get that information from inspecting the actual instance
variable, still TBD on this.

## Resource List

You can obtain a list of managed resources using the `list` or `list!` method.  This method
will return an Array of names.  Again these names could be simple strings or complex values.
The `list!` method causes the framework to re-read from the device.  The `list` method uses the cached value.  
If there is no-cached value, the framework will read from the device, so you don't need to explicity
use `list!` unless you need to force the cache update.

```ruby
pp ndev.l2_ports.list
["fe-0/0/2", "fe-0/0/3", "fe-0/0/6"]
```

## Resource Catalog

You can also obtain the provider's catalog, which is a Hash of resources keyed by name and
each value is the Hash of the associated properties.  The `catalog` and `catalog!` methods
work the same as described in the list section above.

```ruby
pp ndev.l2_ports.catalog
{"fe-0/0/2"=>
  {:_active=>true,
   :_exist=>true,
   :vlan_tagging=>true,
   :tagged_vlans=>["Red", "Green", "Blue"]},
 "fe-0/0/3"=>{:_active=>true, :_exist=>true, :vlan_tagging=>false},
 "fe-0/0/6"=>
  {:_active=>true,
   :_exist=>true,
   :vlan_tagging=>false,
   :untagged_vlan=>"Blue"}}
```

## Selecting a Resource from a Provider

You select a resource from a provider using the `[]` operator and providing a name.  The 
name could be a simple string as shown in the previous example, or could be a complex name
like an Array.  If you take a look a the SRX library (separate repo), you can see that
the Junos::Ez::SRX::Policies::Provider name is an Array of [ from_zone_name, to_zone_name ].  

```ruby
# select L2 switching port "ge-0/0/0" ...

port = ndev.l2_ports['ge-0/0/0']
```

## Creating a new Resource

There are two ways to create a resource.  One is using the `create` or `create!` methods.
The `create` method is used to create the new resource but not write it do the device.  The
`create!` method does both the creation and the write to the device.  The `create` method
can also be given a block, so you can setup the contents of the new resource.  Here's an
example that creates some config and then deactivates it.

```ruby
ndev.l2_ports.create('ge-0/0/20') do |port|
   port[:description] = "I am port 20"
   port[:untagged_vlan] = "Blue"
   port.write!
   port.deactivate!
end
```

The second way is to simply select a resource by name that doesn't exist.  So let's
say you want to create a new L2port for `ge-0/0/20`.  It would look something like this:

```ruby
port = ndev.l2_ports['ge-0/0/20']

puts "I don't exist" unless port.exists?

port[:description] = "I am port 20"
port[:untagged_vlan] = "Storage"
port.write!
```
