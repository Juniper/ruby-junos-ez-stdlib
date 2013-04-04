
require "JunosNC/provider"

module JunosNC::L2ports

  PROPERTIES = [ 
    :untagged_vlan,
    :tagged_vlans,
    :vlan_tagging
  ]  

  def self.Provider( ndev, varsym )        
    
    newbie = case ndev.fact( :switch_style )
    when :VLAN
      JunosNC::L2ports::Provider::VLAN.new( ndev )      
    when :VLAN_NG
      JunosNC::L2ports::Provider::VLAN_NG.new( ndev )            
    when :BRIDGE_DOMAIN
      JunosNC::L2ports::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < JunosNC::Provider::Parent
  end
  
end

=begin
require 'JunosNC/l2ports/vlan'
require 'JunosNC/l2ports/vlan_l2ng'
require 'JunosNC/l2ports/bridge_domain'
=end


