require 'pry'
require 'pp'
require 'net/scp'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
     
# login information for NETCONF session 

login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
print "Connecting to device #{login[:target]} ... "
ndev.open
puts "OK!"

## attach our private & utils that we need ...

Junos::Ez::Provider( ndev )
Junos::Ez::RE::Utils( ndev, :re )
Junos::Ez::FS::Utils( ndev, :fs )

binding.pry

ndev.close
