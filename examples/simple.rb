require 'pry'
require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

unless ARGV[0]
  puts "You must specify a target"
  exit 1
end

# login information for NETCONF session 
login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
$stdout.print "Connecting to device #{login[:target]} ... "
ndev.open
$stdout.puts "OK!"

## Now bind providers to the device object.
## the 'Junos::Ez::Provider' must be first before all others
## this provider will setup the device 'facts'.  The other providers
## allow you to define the instance variables; so this example
## is using 'l1_ports' and 'ip_ports', but you could name them
## what you like, yo!

Junos::Ez::Provider( ndev )
Junos::Ez::L1ports::Provider( ndev, :l1_ports )
Junos::Ez::IPports::Provider( ndev, :ip_ports )

## drop into interactive mode to play around ... let's look
## at what the device has for facts ...

#->  ndev.facts.list
#->  ndev.facts.catalog
#->  ndev.fact :version

## now look at specific providers like the physical (l1) ports ...

#-> ndev.l1_ports.list
#-> ndev.l1_ports.catalog

binding.pry

ndev.close
