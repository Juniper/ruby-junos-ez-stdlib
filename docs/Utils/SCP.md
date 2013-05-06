# `Net::SCP`

The NETCONF object already provides a mechanism to use secure-copy (SCP), so technically this is _not_ part of the `Junos::EZ` framework.  That being said, this is some quick documentation and URLs so you can copy files to and from Junos devices.

# DOCS

For documentation on `Net::SCP`, please refer to this website: http://net-ssh.github.io/scp/v1/api/index.html

# USAGE

The NETCONF object includes an instance variable `scp` that is class `Net::SCP`.

To copy a file from the server to the Junos target, you use the `upload` or `upload!` method.  The bang(!) version is blocking, meaning the code execution will resume only after the file has been completely transfered.

```ruby
file_on_server = "/cygwin/junos/junos-ex4200-image.tgz"
location_on_junos = "/var/tmp"

ndev.scp.upload!( from_on_server, location_on_junos )
```

To copy a file from the Junos target to the server, you use the `download` or `download!` method.

Both upload and download methods can take a Ruby block which is used to provide progress updates on the transfer.  There is a complete "software upgrade" example that illustrates this technique in the _examples_ directory.
