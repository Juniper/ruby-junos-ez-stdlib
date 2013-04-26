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

All resources have the following methods:

  - `read!` - reads the contents into the resource read-hash (@has)
  - `write!` - writes the contents from the resource write-hash (@should) to the device
  - `delete!` - delete the resource from the configuration
  - `activate!` - activates the configuration for this resource
  - `deactivate!` - deactivates the configuration for this resource
  - `exists?` - indicates if this resource exists in the configuration
  - `active?` - indicates if this resource is active in the configuration

# PROVIDERS


  
