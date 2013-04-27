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

Junos::Ez::Provider( ndev )
Junos::Ez::Users::Provider( ndev, :users )
Junos::Ez::UserAuths::Provider( ndev, :auths )
Junos::Ez::Config::Utils( ndev, :cu )

user = ndev.users["jeremy"]

binding.pry

ndev.close
