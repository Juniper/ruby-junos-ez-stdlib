# Junos::Ez::Group::Provider

Manages JUNOS group properties

# EXAMPLE

The provider *name* selector is the JUNOS group name, e.g. "service_group".

```ruby
Junos::Ez::Group::Provider( ndev, :group )

grp = ndev.group["service_group"]

grp[:format] = 'set'
grp[:path] = 'services.set'

grp.write!

```

# PROPERTIES

  - `:format` - JUNOS configuration format is file. It can be 'xml', 'text' or 'set'. Default is 'xml'
  - `:path` - Path of configuration file that is applied inside JUNOS group hierarchy.

# METHODS

No additional methods at this time ...

# USAGE NOTES

Contents of 'service.set' file

````
% cat services.set 
set system services ftp
set system services ssh
set system services netconf ssh
````

JUNOS group configuration reflected on executing above example.

````
{master}[edit]
junos@switch# show groups service_group 
system {
    services {
        ftp;
        ssh;
        netconf {
            ssh;
        }
    }
}

junos@switch# show apply-groups
apply-groups [ global re0 re1 service_group ];

````


