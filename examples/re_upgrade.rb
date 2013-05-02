require 'pry'
require 'pp'
require 'net/scp'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
     
unless ARGV[0]
  puts "You must specify a target"
  exit 1
end

# login information for NETCONF session 

login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
print "Connecting to device #{login[:target]} ... "
ndev.open
puts "OK!"

## attach our private & utils that we need ...

Junos::Ez::Provider( ndev )
Junos::Ez::RE::Utils( ndev, :re )       # routine-engine utils
Junos::Ez::FS::Utils( ndev, :fs )       # filesystem utils

## upload the software image to the target device
## http://net-ssh.github.io/net-scp/

file_name = 'junos-vsrx-domestic.tgz'
file_on_server = '/home/jschulman/junos-images/vsrx/' + file_name
file_on_junos = '/var/tmp/' + file_name

## simple function to use the Netconf::SSH SCP functionality to
## upload a file to the device and watch the percetage tick by ...

def copy_file_to_junos( ndev, file_on_server, file_on_junos )  
  mgr_i = cur_i = 0
  ndev.scp.upload!( file_on_server, file_on_junos ) do |ch, name, sent, total|  
    pct = (sent.to_f / total.to_f) * 100
    mgr_i = pct.to_i
    if mgr_i != cur_i
      cur_i = mgr_i
      puts cur_i.to_s + "%"
    end    
  end
end

puts "Copying file to Junos ..."
copy_file_to_junos( ndev, file_on_server, file_on_junos )

###
### check the MD5 checksum values
###

md5_on_s = Digest::MD5.file( file_on_server ).to_s
md5_on_j = ndev.fs.checksum( :md5, file_on_junos )

if md5_on_s != md5_on_j
  puts "The MD5 checksum values do not match!"
  ndev.close
  exit 1
end

puts "MD5 checksum matches ... proceeding ..."
puts "Validating image ... please wait ..."

unless ndev.re.validate_software?( file_on_junos )
  puts "The softare does not validate!"
  ndev.close
  exit 1
end

puts "Installing image ... please wait ..."
rc = ndev.re.install_software!( :package => file_on_junos, :no_validate => true )
if rc != true
  puts rc
end

### use pry if you want to 'look around'
## -> binding.pry

### if you wanted to reboot the system now, you coud
### do the following ...

## -> ndev.re.reboot!

ndev.close
