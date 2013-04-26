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


  
