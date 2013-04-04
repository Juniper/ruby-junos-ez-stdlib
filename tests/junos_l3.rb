require 'yaml'
require 'net/netconf/jnpr'

require 'JunosNC/facts'
require 'JunosNC/vlans'
require 'JunosNC/ip_ports'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  include JunosNC::Facts
  include JunosNC::IPports
  
  # overload the open method to read the 'facts' from the Junos device and then
  # create a Vlan provider object so we can access the vlans
  
  def open
    super
    facts_read!
    JunosNC::IPports::Provider( self, :ip_ports )    
  end
  
end

host = MyLogins::HOSTS[ARGV[0]]

JunosDevice.new( host ) do |ndev|
  

  binding.pry
  
        
end




