require 'yaml'
require 'net/netconf/jnpr'
require 'Junos/facts'
require 'Junos/vlans'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  include Junos::Facts
  include Junos::Vlans
  
  # overload the open method to read the 'facts' from the Junos device and then
  # create a Vlan provider object so we can access the vlans
  
  def open
    super
    facts_create!
    Junos::Vlans::Provider( self, :Vlans ) 
  end
  
end

JunosDevice.new( MyLogins::EX4 ) do |ndev|
  
  vlan = ndev.Vlans['Jeremy']
  vlan[:description] = "New Jeremy Description"
  vlan.write!
  
  binding.pry
  
end




