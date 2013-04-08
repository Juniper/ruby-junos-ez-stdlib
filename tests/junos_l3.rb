require 'yaml'
require 'net/netconf/jnpr'

require 'junos-ez/facts'
require 'junos-ez/vlans'
require 'junos-ez/ip_ports'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  include Junos::Ez::Facts
  include Junos::Ez::IPports
  
  # overload the open method to read the 'facts' from the Junos device and then
  # create a Vlan provider object so we can access the vlans
  
  def open
    super
    facts_read!
    Junos::Ez::IPports::Provider( self, :ip_ports )    
  end
  
end

host = MyLogins::HOSTS[ARGV[0]]

JunosDevice.new( host ) do |ndev|
  

  binding.pry
  
        
end




