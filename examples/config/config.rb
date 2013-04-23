require 'pry'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
     
# login information for NETCONF session 

login = { :target => 'vsrx', :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
$stdout.print "Connecting to device #{login[:target]} ... "
ndev.open
$stdout.puts "OK!"


Junos::Ez::Provider( ndev )
Junos::Ez::Config::Utils( ndev, :cfg )

# lock the candidate config 
#    ndev.cfg.lock!

# examples of loading ...
#    ndev.cfg.load! :filename => 'load_sample.conf'
#    ndev.cfg.load! :content => File.read( 'load_sample.conf' ), :format => :text
#    ndev.cfg.load! :filename => 'load_sample.set'


binding.pry

# check to see if the config is OK to commit
#   ndev.cfg.commit?  

# perform the commit
#   ndev.cfg.commit!

# unlock the config
#   ndev.cfg.unlock!

ndev.close
